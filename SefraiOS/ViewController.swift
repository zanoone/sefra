import UIKit
import WebKit
import LocalAuthentication
import FirebaseMessaging

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var deviceId: String {
        // UUID에서 하이픈 제거하고 소문자로 변환, 앞 16자리만 사용 (안드로이드와 동일한 형식)
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let cleanUUID = uuid.replacingOccurrences(of: "-", with: "").lowercased()
        return String(cleanUUID.prefix(16))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경을 흰색으로 설정 (상단바 투명 효과)
        view.backgroundColor = .white

        setupWebView()

        // FCM 토큰 업데이트 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(fcmTokenUpdated(_:)), name: NSNotification.Name("FCMTokenUpdated"), object: nil)

        // 알림에서 URL 로드 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(loadURLFromNotification(_:)), name: NSNotification.Name("LoadURLFromNotification"), object: nil)

        // 초기 URL 로드
        loadInitialURL()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent  // 흰색 배경에는 검은색 아이콘
    }

    override var prefersStatusBarHidden: Bool {
        return false  // 상태바 표시
    }

    private func setupWebView() {
        // WKWebView 설정
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // JavaScript Message Handler 추가
        let contentController = WKUserContentController()
        contentController.add(self, name: "AndroidBiometric")
        configuration.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white

        // 쿠키 허용
        if #available(iOS 14.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        view.addSubview(webView)

        // Auto Layout - 상단바 아래에서 시작
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // UserAgent 설정
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Sefra/\(appVersion)"
        webView.customUserAgent = customUserAgent
    }

    private func loadInitialURL() {
        guard let url = URL(string: "https://sefra.kr?device=\(deviceId)") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
        print("초기 URL 로드: \(url.absoluteString)")
    }

    @objc private func fcmTokenUpdated(_ notification: Notification) {
        guard let token = notification.object as? String else { return }
        print("========================================")
        print("FCM 토큰 업데이트됨: \(token.prefix(20))...")
        print("즉시 웹으로 전송 시도...")
        print("========================================")

        // UserDefaults에 저장 (이미 AppDelegate에서 저장되지만 이중 보장)
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.synchronize()

        // 웹뷰가 로드되어 있으면 즉시 전송 (안드로이드와 동일)
        sendFCMTokenToWeb()
    }

    @objc private func loadURLFromNotification(_ notification: Notification) {
        guard let urlString = notification.object as? String,
              let url = URL(string: urlString) else { return }

        let request = URLRequest(url: url)
        webView.load(request)
        print("알림에서 URL 로드: \(urlString)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("========================================")
        print("📄 페이지 로드 완료: \(webView.url?.absoluteString ?? "")")
        print("✅ deviceId: \(deviceId)")
        print("========================================")

        // JavaScript 주입 (안드로이드와 완전히 동일한 로직!)
        let javascript = """
        (function() {
            console.log('========================================');
            console.log('📱 iOS 네이티브 브릿지 초기화 시작');

            // 자동완성 비활성화
            var inputs = document.querySelectorAll('input, textarea');
            inputs.forEach(function(input) {
                input.setAttribute('autocomplete', 'off');
            });

            // PublicKeyCredential polyfill
            if (typeof window.PublicKeyCredential === 'undefined') {
                window.PublicKeyCredential = function() {};
                console.log('PublicKeyCredential polyfill injected');
            }

            // 안드로이드 호환 생체인증 브릿지
            window.AndroidBiometric = {
                authenticate: function() {
                    console.log('🔐 생체인증 호출: authenticate()');
                    window.webkit.messageHandlers.AndroidBiometric.postMessage({
                        action: 'authenticate'
                    });
                },
                isAvailable: function() {
                    console.log('🔍 생체인증 사용 가능 확인');
                    window.webkit.messageHandlers.AndroidBiometric.postMessage({
                        action: 'isAvailable'
                    });
                    return true;
                },
                getFCMToken: function() {
                    // 안드로이드와 동일: 실시간으로 UserDefaults에서 가져옴
                    var token = '';
                    window.webkit.messageHandlers.AndroidBiometric.postMessage({
                        action: 'getFCMToken'
                    });
                    return token;  // 동기 방식이므로 일단 빈 문자열 반환
                }
            };

            console.log('✅ AndroidBiometric 브릿지 준비됨');
            console.log('✅ Native biometric available: true');

            // FCM 토큰을 전역 함수로 노출 (안드로이드와 완전히 동일!)
            window.sendFCMTokenToServer = function() {
                console.log('🔄 sendFCMTokenToServer 호출됨');

                // 네이티브에서 실시간으로 토큰 가져오기
                window.webkit.messageHandlers.AndroidBiometric.postMessage({
                    action: 'sendFCMToken'
                });

                return true;
            };

            // FCM 토큰 즉시 가져올 수 있는 함수도 제공 (안드로이드와 동일)
            window.getFCMToken = function() {
                console.log('⚠️ getFCMToken - iOS에서는 비동기 처리 필요');
                return '';
            };

            console.log('✅ FCM 함수 준비됨: window.sendFCMTokenToServer(), window.getFCMToken()');

            // onB4xDataUpdated 함수가 있으면 자동 전송 (안드로이드와 완전히 동일!)
            if (typeof onB4xDataUpdated === 'function') {
                console.log('✅ onB4xDataUpdated 함수 발견됨');
                // 페이지 로드 후 1초 뒤 FCM 토큰 전송
                setTimeout(function() {
                    console.log('🔄 FCM 토큰 자동 전송 시도...');
                    var result = window.sendFCMTokenToServer();
                    if (result) {
                        console.log('✅ FCM 토큰 자동 전송 요청 완료');
                    } else {
                        console.log('❌ FCM 토큰 자동 전송 실패');
                    }
                }, 1000);
            } else {
                console.log('⚠️ onB4xDataUpdated 함수가 아직 정의되지 않음 (로그인 후 사용 가능할 수 있음)');
            }

            console.log('========================================');
        })();
        """

        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString

        // Custom URL Scheme 처리
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                print("외부 앱 실행: \(urlString)")
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {

    // alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        })
        present(alertController, animated: true, completion: nil)
    }

    // confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        })
        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        })
        present(alertController, animated: true, completion: nil)
    }

    // 새 창 열기 (팝업)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }

        // 현재 웹뷰에서 로드
        webView.load(URLRequest(url: url))
        return nil
    }
}

// MARK: - WKScriptMessageHandler
extension ViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "AndroidBiometric",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        print("JavaScript 메시지 수신: \(action)")

        switch action {
        case "authenticate":
            performBiometricAuthentication()

        case "isAvailable":
            checkBiometricAvailability()

        case "getFCMToken", "sendFCMToken":
            // 안드로이드와 동일: 실시간으로 UserDefaults에서 토큰 가져와서 전송
            sendFCMTokenToWeb()

        default:
            print("알 수 없는 액션: \(action)")
        }
    }

    private func performBiometricAuthentication() {
        print("========================================")
        print("생체인증 시작")
        print("========================================")

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("❌ 생체인증 사용 불가: \(error?.localizedDescription ?? "")")
            sendBiometricResult(success: false, errorMessage: error?.localizedDescription ?? "생체인증을 사용할 수 없습니다")
            return
        }

        let reason = "패스키 인증을 위해 생체인증이 필요합니다"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    print("✅ 생체인증 성공")
                    self?.handleBiometricSuccess()
                } else {
                    print("❌ 생체인증 실패: \(authenticationError?.localizedDescription ?? "")")
                    self?.sendBiometricResult(success: false, errorMessage: authenticationError?.localizedDescription ?? "인증 실패")
                }
            }
        }
    }

    private func handleBiometricSuccess() {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let credentialId = "ios_biometric_\(deviceId)"

        // Challenge와 RpId 가져오기
        webView.evaluateJavaScript("window.passkeyChallenge") { [weak self] challengeResult, _ in
            guard let self = self else { return }

            self.webView.evaluateJavaScript("window.passkeyRpId") { rpIdResult, _ in
                let challenge = (challengeResult as? String) ?? "ios_biometric_challenge_\(timestamp)"
                let rpId = (rpIdResult as? String) ?? "sefra.kr"
                let origin = "https://\(rpId)"

                print("Challenge: \(challenge)")
                print("RpId: \(rpId)")
                print("Credential ID: \(credentialId)")
                print("Origin: \(origin)")

                // ClientDataJSON 생성
                let clientDataJSON = """
                {"type":"webauthn.create","challenge":"\(challenge)","origin":"\(origin)","crossOrigin":false,"ios_biometric":true}
                """
                let clientDataBase64 = clientDataJSON.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                // AttestationObject 생성
                let attestationObject = "ios_biometric_attestation"
                let attestationBase64 = attestationObject.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                let credentialIdBase64 = credentialId.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                // JavaScript 실행
                let javascript = """
                javascript:(function(){
                    try{
                        console.log('[BiometricAuth] JavaScript execution started');
                        var d={
                            id:'\(credentialId)',
                            type:'public-key',
                            clientDataJSON:'\(clientDataBase64)',
                            attestationObject:'\(attestationBase64)',
                            transports:['internal'],
                            ios_biometric:true,
                            device_id:'\(self.deviceId)',
                            timestamp:\(timestamp)
                        };
                        console.log('[BiometricAuth] PasskeyData object created:',JSON.stringify(d));
                        if(window.onBiometricResult){
                            console.log('[BiometricAuth] Calling onBiometricResult...');
                            window.onBiometricResult(true,'Success',d);
                            console.log('[BiometricAuth] onBiometricResult called OK');
                        }else{
                            console.log('[BiometricAuth] ⚠️ window.onBiometricResult NOT FOUND');
                        }
                        var regData={
                            id:'\(credentialId)',
                            rawId:'\(credentialIdBase64)',
                            type:'public-key',
                            response:{
                                clientDataJSON:'\(clientDataBase64)',
                                attestationObject:'\(attestationBase64)'
                            }
                        };
                        console.log('[BiometricAuth] RegData created:',JSON.stringify(regData));
                        if(window.onPasskeyRegistered){
                            console.log('[BiometricAuth] Calling onPasskeyRegistered...');
                            window.onPasskeyRegistered(JSON.stringify(regData));
                            console.log('[BiometricAuth] onPasskeyRegistered called OK');
                        }else{
                            console.log('[BiometricAuth] ℹ️ window.onPasskeyRegistered NOT FOUND');
                        }
                        if(window.onBiometricLoginSuccess){
                            console.log('[BiometricAuth] Calling onBiometricLoginSuccess...');
                            window.onBiometricLoginSuccess(d);
                            console.log('[BiometricAuth] ✅ onBiometricLoginSuccess called OK');
                        }else{
                            console.log('[BiometricAuth] ⚠️ window.onBiometricLoginSuccess NOT FOUND');
                        }
                        console.log('[BiometricAuth] JavaScript execution finished');
                    }catch(e){
                        console.error('[BiometricAuth] ❌ JavaScript Error:',e);
                        console.error('[BiometricAuth] Error stack:',e.stack);
                        alert('BiometricAuth JS Error: '+e.message);
                    }
                })();
                """

                print("=== JavaScript 실행 ===")
                self.webView.evaluateJavaScript(javascript) { result, error in
                    if let error = error {
                        print("❌ JavaScript 실행 오류: \(error.localizedDescription)")
                    } else {
                        print("✅ JavaScript 실행 완료")
                    }
                }
            }
        }
    }

    private func sendBiometricResult(success: Bool, errorMessage: String = "") {
        let escapedMessage = errorMessage.replacingOccurrences(of: "'", with: "\\'")
        let javascript = "if(window.onBiometricResult) window.onBiometricResult(\(success), '\(escapedMessage)');"
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }

    private func checkBiometricAvailability() {
        let context = LAContext()
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        let javascript = "window.biometricAvailable = \(available);"
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }

    private func sendFCMTokenToWeb() {
        let token = UserDefaults.standard.string(forKey: "fcm_token") ?? ""

        if token.isEmpty {
            print("⚠️ FCM 토큰이 아직 없음")
            return
        }

        print("FCM 토큰 웹으로 전송: \(token.prefix(20))...")

        let javascript = """
        (function() {
            var fcmToken = '\(token)';

            if (fcmToken && fcmToken.length > 0) {
                console.log('FCM Token available:', fcmToken.substring(0, 30) + '...');

                if (typeof onB4xDataUpdated === 'function') {
                    onB4xDataUpdated({ fcmToken: fcmToken });
                    console.log('✅ onB4xDataUpdated 함수 호출됨 (fcmToken 전달)');
                    return true;
                } else {
                    console.warn('⚠️ onB4xDataUpdated 함수가 정의되지 않음');
                    return false;
                }
            } else {
                console.warn('⚠️ FCM 토큰이 아직 준비되지 않음');
                return false;
            }
        })();
        """

        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }

}
