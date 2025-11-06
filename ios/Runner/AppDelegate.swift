import Flutter
import UIKit
// FIREBASE TEMPORARILY DISABLED FOR DEBUGGING (v1.0.0+22)
// import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FIREBASE INITIALIZATION DISABLED FOR DEBUGGING (v1.0.0+22)
    // Testing if Firebase is causing the crash on real devices
    // FirebaseApp.configure()

    print("⚠️ DEBUG MODE: Firebase initialization skipped")

    // Register plugins before calling super to avoid QoS warning
    GeneratedPluginRegistrant.register(with: self)

    // Call super on main thread with proper QoS
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    return result
  }
}
