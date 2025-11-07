import UIKit
import WebKit
import LocalAuthentication

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    var deviceId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Device ID 생성 (Android의 ANDROID_ID와 유사)
        deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""

        // WebView 설정
        setupWebView()

        // 알림 옵저버 등록
        setupNotificationObservers()

        // 초기 URL 로드
        let urlString = "https://sefra.kr?device=\(deviceId)"
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
            print("🌐 WebView 로드: \(urlString)")
        }
    }

    // MARK: - WebView 설정
    func setupWebView() {
        let contentController = WKUserContentController()

        // JavaScript Bridge 등록 (Android의 JavascriptInterface와 동일)
        contentController.add(self, name: "iOSBiometric")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true

        // 쿠키 허용
        config.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self

        // iOS 버전 정보를 포함한 User-Agent 설정
        let systemVersion = UIDevice.current.systemVersion
        let modelName = UIDevice.current.model
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Sefra/1.0"

        // Auto Layout
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 스와이프 제스처로 뒤로가기
        webView.allowsBackForwardNavigationGestures = true

        print("✅ WebView 설정 완료")
    }

    // MARK: - 알림 옵저버 설정
    func setupNotificationObservers() {
        // FCM 토큰 수신 알림
        NotificationCenter.default.addObserver(self, selector: #selector(handleFCMToken(_:)), name: NSNotification.Name("FCMTokenReceived"), object: nil)

        // 푸시 알림 클릭 알림
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationClick(_:)), name: NSNotification.Name("NotificationClicked"), object: nil)

        // URL Scheme 처리
        NotificationCenter.default.addObserver(self, selector: #selector(handleURLScheme(_:)), name: NSNotification.Name("HandleURLScheme"), object: nil)
    }

    @objc func handleFCMToken(_ notification: Notification) {
        guard let token = notification.object as? String else { return }
        print("📱 FCM 토큰 수신됨, 웹으로 전달 준비: \(token.prefix(30))...")
    }

    @objc func handleNotificationClick(_ notification: Notification) {
        guard let targetUrl = notification.object as? String, let url = URL(string: targetUrl) else { return }
        print("🔔 알림 클릭, URL 이동: \(targetUrl)")
        webView.load(URLRequest(url: url))
    }

    @objc func handleURLScheme(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        print("🔗 URL Scheme 처리: \(url.absoluteString)")
        // WebView를 새로고침하거나 특정 동작 수행
        webView.reload()
    }

    // MARK: - WKScriptMessageHandler (JavaScript Bridge)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "iOSBiometric" else { return }

        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else {
            print("⚠️ JavaScript 메시지 형식 오류")
            return
        }

        print("📞 JavaScript 메시지 수신: \(method)")

        switch method {
        case "authenticate":
            authenticateWithBiometric()

        case "isAvailable":
            let available = isBiometricAvailable()
            let js = "window.onBiometricAvailableResult && window.onBiometricAvailableResult(\(available));"
            webView.evaluateJavaScript(js, completionHandler: nil)

        case "getFCMToken":
            let token = UserDefaults.standard.string(forKey: "fcm_token") ?? ""
            let js = "window.onFCMTokenResult && window.onFCMTokenResult('\(token)');"
            webView.evaluateJavaScript(js, completionHandler: nil)
            print("🔑 FCM 토큰 전달: \(token.prefix(30))...")

        default:
            print("⚠️ 알 수 없는 메서드: \(method)")
        }
    }

    // MARK: - 생체인증
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            print("⚠️ 생체인증 사용 불가: \(error.localizedDescription)")
        }

        return canEvaluate
    }

    func authenticateWithBiometric() {
        let context = LAContext()
        context.localizedCancelTitle = "취소"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("❌ 생체인증 불가: \(error?.localizedDescription ?? "Unknown error")")
            sendBiometricResult(success: false, message: error?.localizedDescription ?? "생체인증을 사용할 수 없습니다")
            return
        }

        print("🔐 생체인증 시작...")

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "패스키 인증") { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ 생체인증 성공!")
                    self.sendBiometricSuccess()
                } else {
                    let errorMessage = error?.localizedDescription ?? "인증 실패"
                    print("❌ 생체인증 실패: \(errorMessage)")
                    self.sendBiometricResult(success: false, message: errorMessage)
                }
            }
        }
    }

    func sendBiometricSuccess() {
        // Android와 동일한 형식의 Passkey 데이터 생성
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let credentialId = "ios_biometric_\(deviceId)"

        // Challenge 및 RpId 가져오기
        webView.evaluateJavaScript("window.passkeyChallenge") { challengeResult, _ in
            self.webView.evaluateJavaScript("window.passkeyRpId") { rpIdResult, _ in

                let challenge = (challengeResult as? String)?.replacingOccurrences(of: "\"", with: "") ?? "ios_biometric_challenge_\(timestamp)"
                let rpId = (rpIdResult as? String)?.replacingOccurrences(of: "\"", with: "") ?? "sefra.kr"
                let origin = "https://\(rpId)"

                print("🔐 Challenge: \(challenge)")
                print("🔐 RpId: \(rpId)")
                print("🔐 Credential ID: \(credentialId)")

                // ClientDataJSON 생성
                let clientDataJSON = """
                {"type":"webauthn.create","challenge":"\(challenge)","origin":"\(origin)","crossOrigin":false,"ios_biometric":true}
                """
                let clientDataBase64 = clientDataJSON.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                // Attestation Object 생성
                let attestationObject = "ios_biometric_attestation"
                let attestationBase64 = attestationObject.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                print("🔐 ClientData Base64: \(clientDataBase64.prefix(50))...")
                print("🔐 Attestation Base64: \(attestationBase64.prefix(50))...")

                // JavaScript로 데이터 전달
                let passkeyData = """
                {
                    id: '\(credentialId)',
                    type: 'public-key',
                    clientDataJSON: '\(clientDataBase64)',
                    attestationObject: '\(attestationBase64)',
                    transports: ['internal'],
                    ios_biometric: true,
                    device_id: '\(self.deviceId)',
                    timestamp: \(timestamp)
                }
                """

                let rawId = credentialId.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                let regData = """
                {
                    id: '\(credentialId)',
                    rawId: '\(rawId)',
                    type: 'public-key',
                    response: {
                        clientDataJSON: '\(clientDataBase64)',
                        attestationObject: '\(attestationBase64)'
                    }
                }
                """

                let jsCode = """
                (function() {
                    try {
                        console.log('[BiometricAuth] iOS 생체인증 성공!');

                        var d = \(passkeyData);
                        console.log('[BiometricAuth] PasskeyData:', JSON.stringify(d));

                        if (window.onBiometricResult) {
                            window.onBiometricResult(true, 'Success', d);
                            console.log('[BiometricAuth] onBiometricResult 호출 완료');
                        } else {
                            console.log('[BiometricAuth] ⚠️ onBiometricResult 없음');
                        }

                        var regData = \(regData);
                        if (window.onPasskeyRegistered) {
                            window.onPasskeyRegistered(JSON.stringify(regData));
                            console.log('[BiometricAuth] onPasskeyRegistered 호출 완료');
                        }

                        if (window.onBiometricLoginSuccess) {
                            window.onBiometricLoginSuccess(d);
                            console.log('[BiometricAuth] ✅ onBiometricLoginSuccess 호출 완료');
                        } else {
                            console.log('[BiometricAuth] ⚠️ onBiometricLoginSuccess 없음');
                        }
                    } catch (e) {
                        console.error('[BiometricAuth] ❌ 에러:', e);
                    }
                })();
                """

                print("📤 JavaScript 실행 중...")
                self.webView.evaluateJavaScript(jsCode) { result, error in
                    if let error = error {
                        print("❌ JavaScript 실행 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ JavaScript 실행 성공")
                    }
                }
            }
        }
    }

    func sendBiometricResult(success: Bool, message: String) {
        let js = "window.onBiometricResult && window.onBiometricResult(\(success), '\(message)');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("📄 페이지 로드 완료: \(webView.url?.absoluteString ?? "")")

        // JavaScript 초기화 코드 주입
        let initJS = """
        (function() {
            console.log('✅ iOS WebView 초기화');

            // FCM 토큰 가져오기 함수
            window.getFCMToken = function() {
                return new Promise((resolve) => {
                    window.onFCMTokenResult = function(token) {
                        resolve(token);
                        delete window.onFCMTokenResult;
                    };
                    window.webkit.messageHandlers.iOSBiometric.postMessage({method: 'getFCMToken'});
                });
            };

            // 생체인증 함수
            window.iOSBiometric = {
                authenticate: function() {
                    console.log('🔐 생체인증 요청');
                    window.webkit.messageHandlers.iOSBiometric.postMessage({method: 'authenticate'});
                },
                isAvailable: function() {
                    return new Promise((resolve) => {
                        window.onBiometricAvailableResult = function(available) {
                            resolve(available);
                            delete window.onBiometricAvailableResult;
                        };
                        window.webkit.messageHandlers.iOSBiometric.postMessage({method: 'isAvailable'});
                    });
                }
            };

            // Android와의 호환성을 위한 Alias
            window.AndroidBiometric = window.iOSBiometric;

            // FCM 토큰 전송 함수
            window.sendFCMTokenToServer = async function() {
                try {
                    var fcmToken = await window.getFCMToken();
                    if (fcmToken && fcmToken.length > 0) {
                        console.log('FCM Token:', fcmToken.substring(0, 30) + '...');
                        if (typeof onB4xDataUpdated === 'function') {
                            onB4xDataUpdated({ fcmToken: fcmToken });
                            console.log('✅ onB4xDataUpdated 호출됨');
                            return true;
                        } else {
                            console.warn('⚠️ onB4xDataUpdated 없음');
                            return false;
                        }
                    }
                } catch (e) {
                    console.error('❌ FCM 토큰 처리 실패:', e);
                    return false;
                }
            };

            // 페이지 로드 후 FCM 토큰 자동 전송
            if (typeof onB4xDataUpdated === 'function') {
                setTimeout(function() {
                    window.sendFCMTokenToServer();
                }, 1000);
            }

            console.log('✅ iOS WebView 스크립트 로드 완료');
        })();
        """

        webView.evaluateJavaScript(initJS, completionHandler: nil)
    }

    // 새 창 열기 처리 (팝업)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // URL 로딩 전 처리
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString

        // Custom URL Scheme 처리 (본인인증 등)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            print("🔗 External URL Scheme: \(urlString)")

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
