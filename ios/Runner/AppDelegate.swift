import Flutter
import UIKit
// import Firebase // DISABLED FOR TESTING v1.0.0+26

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase - DISABLED FOR TESTING v1.0.0+26
    // FirebaseApp.configure()

    // Register plugins before calling super to avoid QoS warning
    GeneratedPluginRegistrant.register(with: self)

    // Call super on main thread with proper QoS
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    return result
  }
}
