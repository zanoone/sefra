import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase 초기화
        FirebaseApp.configure()

        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self

        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("알림 권한 승인됨")
            } else {
                print("알림 권한 거부됨: \(error?.localizedDescription ?? "")")
            }
        }

        application.registerForRemoteNotifications()

        // 윈도우 설정
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white  // 상단바를 투명하게 만들기 위해 배경을 흰색으로 설정
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

    // APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs 토큰 등록 성공")
        Messaging.messaging().apnsToken = deviceToken
    }

    // APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 토큰 등록 실패: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {

    // FCM 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        print("FCM 토큰: \(token)")

        // UserDefaults에 저장
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.synchronize()

        // general 토픽 구독
        Messaging.messaging().subscribe(toTopic: "general") { error in
            if let error = error {
                print("general 토픽 구독 실패: \(error.localizedDescription)")
            } else {
                print("general 토픽 구독 성공")
            }
        }

        // 웹뷰에 FCM 토큰이 업데이트되었음을 알림
        NotificationCenter.default.post(name: NSNotification.Name("FCMTokenUpdated"), object: token)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    // 포그라운드에서 알림 수신
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("포그라운드 알림 수신: \(userInfo)")

        // iOS 14 이상
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // 알림 탭 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("알림 탭됨: \(userInfo)")

        // target_url이 있으면 해당 URL로 이동
        if let targetUrl = userInfo["target_url"] as? String, !targetUrl.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name("LoadURLFromNotification"), object: targetUrl)
        }

        completionHandler()
    }
}
