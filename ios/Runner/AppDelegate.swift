import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Register plugins before calling super to avoid QoS warning
    GeneratedPluginRegistrant.register(with: self)

    // Call super on main thread with proper QoS
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    return result
  }
}
