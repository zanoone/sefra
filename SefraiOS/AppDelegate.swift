import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseInstallations
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // 디버그 로그를 ViewController에 전송하는 헬퍼 함수
    private func debugLog(_ message: String) {
        print(message)  // Xcode 콘솔에도 출력
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("AppDelegateLog"), object: message)
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase 초기화
        FirebaseApp.configure()

        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self

        // 🔥 GoogleService-Info.plist 앱 ID가 바뀌었으므로 FCM 토큰 강제 삭제 및 재발급
        let currentAppID = "1:490906882581:ios:cf31c2772398ca5e66741c"
        let savedAppID = UserDefaults.standard.string(forKey: "google_app_id")
        let tokenResetFlag = UserDefaults.standard.bool(forKey: "fcm_token_reset_v41")

        // 앱 ID가 바뀌었거나, 토큰 리셋 플래그가 false면 (한 번도 리셋 안 했으면)
        if savedAppID != currentAppID || !tokenResetFlag {
            debugLog("========================================")
            debugLog("🔥 FCM 토큰 & Firebase Installations ID 강제 삭제")
            debugLog("   기존 앱 ID: \(savedAppID ?? "없음")")
            debugLog("   새 앱 ID: \(currentAppID)")
            debugLog("========================================")

            // 1단계: Firebase Installations ID 삭제 (Keychain에서 삭제)
            Installations.installations().delete { error in
                if let error = error {
                    debugLog("❌ Firebase Installations ID 삭제 실패: \(error.localizedDescription)")
                } else {
                    debugLog("✅ Firebase Installations ID 삭제 성공! (Keychain 포함)")
                }
            }

            // 2단계: FCM 토큰 삭제
            Messaging.messaging().deleteToken { error in
                if let error = error {
                    debugLog("❌ FCM 토큰 삭제 실패: \(error.localizedDescription)")
                } else {
                    debugLog("✅ FCM 토큰 삭제 성공!")

                    // 새 앱 ID 저장 및 리셋 플래그 설정
                    UserDefaults.standard.set(currentAppID, forKey: "google_app_id")
                    UserDefaults.standard.set(true, forKey: "fcm_token_reset_v41")
                    UserDefaults.standard.synchronize()

                    // 토큰 즉시 재발급 요청
                    Messaging.messaging().token { token, error in
                        if let error = error {
                            debugLog("❌ 새 FCM 토큰 발급 실패: \(error.localizedDescription)")
                        } else if let token = token {
                            debugLog("✅ 새 FCM 토큰 발급 성공!")
                            debugLog("🆕 새 토큰: \(token)")

                            // UserDefaults에 저장
                            UserDefaults.standard.set(token, forKey: "fcm_token")
                            UserDefaults.standard.synchronize()

                            // general 토픽 구독
                            Messaging.messaging().subscribe(toTopic: "general") { error in
                                if let error = error {
                                    debugLog("❌ general 토픽 구독 실패: \(error.localizedDescription)")
                                } else {
                                    debugLog("✅ general 토픽 구독 성공")
                                }
                            }

                            // 웹뷰에 알림
                            NotificationCenter.default.post(name: NSNotification.Name("FCMTokenUpdated"), object: token)
                        }
                    }
                }
            }
        } else {
            debugLog("✅ GoogleService-Info.plist 앱 ID 일치: \(currentAppID)")
        }

        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                debugLog("알림 권한 승인됨")
            } else {
                debugLog("알림 권한 거부됨: \(error?.localizedDescription ?? "")")
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
        debugLog("APNs 토큰 등록 성공")
        Messaging.messaging().apnsToken = deviceToken
    }

    // APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugLog("APNs 토큰 등록 실패: \(error.localizedDescription)")
    }

    // 백그라운드에서 푸시 알림 수신 (중요!)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        debugLog("========================================")
        debugLog("백그라운드 푸시 알림 수신")
        debugLog("========================================")
        debugLog("userInfo: \(userInfo)")

        // FCM 데이터 메시지 처리
        if let messageID = userInfo["gcm.message_id"] {
            debugLog("FCM Message ID: \(messageID)")
        }

        // 커스텀 데이터 처리
        if let aps = userInfo["aps"] as? [String: Any] {
            debugLog("APS: \(aps)")
        }

        // Firebase Analytics 이벤트 전송
        Messaging.messaging().appDidReceiveMessage(userInfo)

        // 백그라운드 작업 완료
        completionHandler(.newData)
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {

    // FCM 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        debugLog("FCM 토큰: \(token)")

        // UserDefaults에 저장
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.synchronize()

        // general 토픽 구독
        Messaging.messaging().subscribe(toTopic: "general") { error in
            if let error = error {
                debugLog("general 토픽 구독 실패: \(error.localizedDescription)")
            } else {
                debugLog("general 토픽 구독 성공")
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
        debugLog("포그라운드 알림 수신: \(userInfo)")

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
        debugLog("알림 탭됨: \(userInfo)")

        // target_url이 있으면 해당 URL로 이동
        if let targetUrl = userInfo["target_url"] as? String, !targetUrl.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name("LoadURLFromNotification"), object: targetUrl)
        }

        completionHandler()
    }
}
