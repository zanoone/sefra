import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // DISABLED FOR TESTING v1.0.0+26
import 'package:local_auth/local_auth.dart';
// import 'package:firebase_core/firebase_core.dart'; // DISABLED FOR TESTING v1.0.0+26
// import 'package:firebase_messaging/firebase_messaging.dart'; // DISABLED FOR TESTING v1.0.0+26
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
// import 'firebase_options.dart'; // DISABLED FOR TESTING v1.0.0+26

// Background message handler (must be top-level function)
// Firebase is already initialized in native iOS code (AppDelegate.swift)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // No need to initialize Firebase here - already done in native code
//   print('📬 Background message: ${message.notification?.title}');
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase DISABLED FOR TESTING v1.0.0+26
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   print('✅ Firebase initialized successfully');
  //   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //   print('✅ Background message handler registered');
  // } catch (e) {
  //   print('❌ Firebase initialization error: $e');
  //   print('⚠️ App will continue without Firebase features');
  // }

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
  // InAppWebViewController? webViewController; // DISABLED FOR TESTING v1.0.0+26
  final LocalAuthentication auth = LocalAuthentication();
  String deviceId = '';
  String fcmToken = '';
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getDeviceId();
    // await _setupFCM(); // DISABLED FOR TESTING v1.0.0+26
    setState(() {
      isInitialized = true;
    });
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

  // Setup Firebase Cloud Messaging - DISABLED FOR TESTING v1.0.0+26
  // Future<void> _setupFCM() async {
  //   try {
  //     NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );
  //     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //       print('✅ User granted notification permission');
  //     } else {
  //       print('⚠️ Notification permission denied');
  //     }
  //     fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
  //     print('✅ FCM Token: ${fcmToken.isNotEmpty ? "Obtained" : "Empty"}');
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('fcm_token', fcmToken);
  //     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  //       fcmToken = newToken;
  //       prefs.setString('fcm_token', newToken);
  //       print('🔄 FCM Token refreshed');
  //     });
  //     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //       print('📬 Foreground message: ${message.notification?.title}');
  //       if (message.notification != null) {
  //         _showNotificationDialog(
  //           message.notification!.title ?? 'Notification',
  //           message.notification!.body ?? '',
  //         );
  //       }
  //     });
  //     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //       print('👆 Notification tapped: ${message.data}');
  //     });
  //     print('✅ FCM setup completed successfully');
  //   } catch (e) {
  //     print('❌ Error setting up FCM: $e');
  //   }
  // }

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
    // 초기화 완료될 때까지 로딩 화면 표시
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Simple test screen without WebView (v1.0.0+26 testing)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sefra Test (v1.0.0+27)'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WebView Disabled for Testing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Testing if flutter_inappwebview was causing the crash.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              const Text(
                'App Information:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Version', '1.0.0+27'),
              _buildInfoRow('Device ID', deviceId.isEmpty ? 'Loading...' : deviceId),
              _buildInfoRow('FCM Token', fcmToken.isEmpty ? 'Not available' : 'Obtained'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final result = await _authenticate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success']
                          ? 'Authentication successful!'
                          : 'Authentication failed: ${result['error']}',
                      ),
                    ),
                  );
                },
                child: const Text('Test Biometric Authentication'),
              ),
              const SizedBox(height: 30),
              const Text(
                'If this screen displays correctly on the real device, then flutter_inappwebview was the cause of the crash.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
