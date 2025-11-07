import UIKit
import Firebase
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase 초기화
        FirebaseApp.configure()

        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self

        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("✅ 푸시 알림 권한 승인됨")
            } else {
                print("⚠️ 푸시 알림 권한 거부됨")
            }
        }

        // APNs 등록
        application.registerForRemoteNotifications()

        // 앱 토픽 구독 (Android의 "general" 토픽과 동일)
        Messaging.messaging().subscribe(toTopic: "general") { error in
            if let error = error {
                print("❌ 'general' 토픽 구독 실패: \(error.localizedDescription)")
            } else {
                print("✅ 'general' 토픽 구독 성공")
            }
        }

        return true
    }

    // APNs 토큰 수신
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs 토큰 수신: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // APNs 토큰을 Firebase에 전달
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs 등록 실패: \(error.localizedDescription)")
    }

    // URL Scheme 처리 (본인인증 등에서 앱으로 돌아올 때)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 URL Scheme 수신: \(url.absoluteString)")

        // ViewController에 알림 전달 (필요시)
        NotificationCenter.default.post(name: NSNotification.Name("HandleURLScheme"), object: url)

        return true
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    // 포그라운드에서 알림 수신 시 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📬 포그라운드 알림 수신: \(userInfo)")

        // iOS 14 이상
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // 알림 클릭 시 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 알림 클릭됨: \(userInfo)")

        // 특정 URL로 이동해야 할 경우
        if let targetUrl = userInfo["target_url"] as? String, !targetUrl.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name("NotificationClicked"), object: targetUrl)
        }

        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {

    // FCM 토큰 수신/갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        print("✅ FCM 토큰 수신: \(token)")

        // UserDefaults에 저장
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.synchronize()

        print("💾 FCM 토큰 저장 완료")

        // 웹뷰에 토큰 전달 (NotificationCenter 사용)
        NotificationCenter.default.post(name: NSNotification.Name("FCMTokenReceived"), object: token)
    }
}
