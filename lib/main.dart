import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const SefraApp());
}

class SefraApp extends StatelessWidget {
  const SefraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sefra',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  final LocalAuthentication auth = LocalAuthentication();
  String deviceId = '';
  String fcmToken = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getDeviceId();
    await _setupFCM();
  }

  // Get device ID
  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      }
      print('Device ID: $deviceId');
    } catch (e) {
      print('Error getting device ID: $e');
    }
  }

  // Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    try {
      // Request notification permission (iOS)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      }

      // Get FCM token
      fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      print('FCM Token: $fcmToken');

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        prefs.setString('fcm_token', newToken);
        print('FCM Token refreshed: $newToken');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message: ${message.notification?.title}');

        // Show notification to user
        if (message.notification != null) {
          _showNotificationDialog(
            message.notification!.title ?? 'Notification',
            message.notification!.body ?? '',
          );
        }
      });

      // Handle notification tap (app opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification tapped: ${message.data}');
      });
    } catch (e) {
      print('Error setting up FCM: $e');
    }
  }

  // Show notification dialog
  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Biometric authentication
  Future<Map<String, dynamic>> _authenticate() async {
    try {
      // Check if biometric is available
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return {
          'success': false,
          'error': 'Biometric authentication not available'
        };
      }

      // Authenticate
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access Sefra',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Success - return credential data
        return {
          'success': true,
          'id': 'biometric_$deviceId',
          'type': 'public-key',
          'device_id': deviceId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        return {
          'success': false,
          'error': 'Authentication failed'
        };
      }
    } catch (e) {
      print('Authentication error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://test.sefra.com?device=$deviceId'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            cacheEnabled: true,
            useOnDownloadStart: true,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;

            // Register JavaScript handlers
            controller.addJavaScriptHandler(
              handlerName: 'authenticate',
              callback: (args) async {
                final result = await _authenticate();
                return result;
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'getFCMToken',
              callback: (args) async {
                final prefs = await SharedPreferences.getInstance();
                return prefs.getString('fcm_token') ?? fcmToken;
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'isAvailable',
              callback: (args) async {
                final canCheckBiometrics = await auth.canCheckBiometrics;
                final isDeviceSupported = await auth.isDeviceSupported();
                return canCheckBiometrics && isDeviceSupported;
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'getDeviceId',
              callback: (args) async {
                return deviceId;
              },
            );
          },
          onLoadStop: (controller, url) async {
            // Inject JavaScript bridge
            await controller.evaluateJavascript(source: """
              // Biometric authentication bridge
              window.AndroidBiometric = {
                authenticate: async function() {
                  try {
                    const result = await window.flutter_inappwebview.callHandler('authenticate');
                    if (result.success && window.onBiometricLoginSuccess) {
                      window.onBiometricLoginSuccess(result);
                    }
                    return result;
                  } catch (e) {
                    console.error('Biometric auth error:', e);
                    return { success: false, error: e.toString() };
                  }
                },
                isAvailable: async function() {
                  return await window.flutter_inappwebview.callHandler('isAvailable');
                }
              };

              // FCM functions
              window.getFCMToken = async function() {
                return await window.flutter_inappwebview.callHandler('getFCMToken');
              };

              window.sendFCMTokenToServer = async function() {
                try {
                  const token = await window.getFCMToken();
                  if (typeof onB4xDataUpdated === 'function') {
                    onB4xDataUpdated({ fcmToken: token });
                    return true;
                  }
                  return false;
                } catch (e) {
                  console.error('FCM token error:', e);
                  return false;
                }
              };

              // Device ID function
              window.getDeviceId = async function() {
                return await window.flutter_inappwebview.callHandler('getDeviceId');
              };

              console.log('✅ Sefra Flutter WebView Bridge Ready');
              console.log('✅ Device ID: $deviceId');
              console.log('✅ FCM Token: ${fcmToken.isNotEmpty ? "Available" : "Loading..."}');
            """);
          },
          onConsoleMessage: (controller, consoleMessage) {
            // Log console messages for debugging
            print('JS Console: ${consoleMessage.message}');
          },
          onLoadError: (controller, url, code, message) {
            print('Load error: $message');
          },
        ),
      ),
    );
  }
}
