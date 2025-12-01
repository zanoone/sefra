import UIKit
import WebKit
import LocalAuthentication
import FirebaseMessaging

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var popupWebView: WKWebView?
    private var debugLogView: UITextView!
    private var debugLogs: [String] = []
    private var isDebugViewVisible = true

    private var deviceId: String {
        // 전체 UUID 사용 (하이픈 포함)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경을 흰색으로 설정 (상단바 투명 효과)
        view.backgroundColor = .white

        setupWebView()
        setupDebugLogView()

        // FCM 토큰 업데이트 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(fcmTokenUpdated(_:)), name: NSNotification.Name("FCMTokenUpdated"), object: nil)

        // 알림에서 URL 로드 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(loadURLFromNotification(_:)), name: NSNotification.Name("LoadURLFromNotification"), object: nil)

        // AppDelegate 로그 알림 수신
        // NotificationCenter.default.addObserver(self, selector: #selector(appDelegateLogReceived(_:)), name: NSNotification.Name("AppDelegateLog"), object: nil)

        // 초기 URL 로드
        loadInitialURL()

        addDebugLog("🚀 앱 시작")
        addDebugLog("📱 Device ID: \(deviceId)")
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
        // window.open() 팝업 허용 (nice.checkplus.co.kr 본인인증 팝업 필요)
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // JavaScript Message Handler 추가
        let contentController = WKUserContentController()
        contentController.add(self, name: "AndroidBiometric")
        contentController.add(self, name: "ConsoleLog")
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
        // addDebugLog("🌐 초기 URL 로드: \(url.absoluteString)")
    }

    @objc private func fcmTokenUpdated(_ notification: Notification) {
        guard let token = notification.object as? String else { return }
        // addDebugLog("🔥 FCM 토큰 업데이트: \(token.prefix(20))...")
        // addDebugLog("📤 즉시 웹으로 전송 시도")

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

    @objc private func appDelegateLogReceived(_ notification: Notification) {
        guard let logMessage = notification.object as? String else { return }
        // addDebugLog(logMessage)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // addDebugLog("📄 페이지 로드 완료: \(webView.url?.absoluteString ?? "")")
        // addDebugLog("✅ deviceId: \(deviceId)")

        // JavaScript 주입 (안드로이드와 완전히 동일한 로직!)
        let javascript = """
        (function() {
            // console.log 캡처
            var originalConsoleLog = console.log;
            console.log = function() {
                var message = Array.from(arguments).map(function(arg) {
                    if (typeof arg === 'object') {
                        try { return JSON.stringify(arg); } catch(e) { return String(arg); }
                    }
                    return String(arg);
                }).join(' ');

                window.webkit.messageHandlers.ConsoleLog.postMessage({
                    message: message,
                    type: 'log'
                });

                originalConsoleLog.apply(console, arguments);
            };

            // console.error 캡처
            var originalConsoleError = console.error;
            console.error = function() {
                var message = Array.from(arguments).map(function(arg) {
                    if (typeof arg === 'object') {
                        try { return JSON.stringify(arg); } catch(e) { return String(arg); }
                    }
                    return String(arg);
                }).join(' ');

                window.webkit.messageHandlers.ConsoleLog.postMessage({
                    message: message,
                    type: 'error'
                });

                originalConsoleError.apply(console, arguments);
            };

            // console.warn 캡처
            var originalConsoleWarn = console.warn;
            console.warn = function() {
                var message = Array.from(arguments).map(function(arg) {
                    if (typeof arg === 'object') {
                        try { return JSON.stringify(arg); } catch(e) { return String(arg); }
                    }
                    return String(arg);
                }).join(' ');

                window.webkit.messageHandlers.ConsoleLog.postMessage({
                    message: message,
                    type: 'warn'
                });

                originalConsoleWarn.apply(console, arguments);
            };

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

            // FCM 토큰을 전역 함수로 노출 (안드로이드와 호환)
            // iOS는 동기 호출 불가하므로 메시지만 전송
            window.sendFCMTokenToServer = function() {
                console.log('🔄 sendFCMTokenToServer 호출됨');
                window.webkit.messageHandlers.AndroidBiometric.postMessage({
                    action: 'sendFCMToken'
                });
                return true;
            };

            // FCM 토큰 즉시 가져올 수 있는 함수 (iOS는 동기 반환 불가)
            window.getFCMToken = function() {
                console.log('⚠️ getFCMToken 호출 - iOS는 동기 불가, sendFCMTokenToServer() 사용 권장');
                return '';
            };

            console.log('✅ FCM 함수 준비됨: window.sendFCMTokenToServer(), window.getFCMToken()');

            // 페이지 로드 후 1초 뒤 자동 전송
            setTimeout(function() {
                console.log('🔄 FCM 토큰 자동 전송 시도...');
                var result = window.sendFCMTokenToServer();
                if (result) {
                    console.log('✅ FCM 토큰 자동 전송 요청 완료');
                } else {
                    console.log('❌ FCM 토큰 자동 전송 실패');
                }
            }, 1000);

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

        // window.open() 호출 시 새로운 팝업 WebView 생성 (nice.checkplus.co.kr 본인인증 팝업)
        let popup = WKWebView(frame: view.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        self.popupWebView = popup

        // 팝업 WebView 추가 (SafeArea 아래에서 시작)
        view.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            popup.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            popup.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        popup.load(URLRequest(url: url))
        return popup
    }

    // 팝업 닫기 처리 (JavaScript window.close() 호출 시)
    func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            popupWebView?.removeFromSuperview()
            popupWebView = nil
        }
    }
}

// MARK: - WKScriptMessageHandler
extension ViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // ConsoleLog 메시지 처리
        if message.name == "ConsoleLog" {
            if let body = message.body as? [String: Any],
               let logMessage = body["message"] as? String,
               let logType = body["type"] as? String {
                var prefix = "📝"
                if logType == "error" {
                    prefix = "❌"
                } else if logType == "warn" {
                    prefix = "⚠️"
                }
                addDebugLog("\(prefix) \(logMessage)")
            }
            return
        }

        // AndroidBiometric 메시지 처리
        guard message.name == "AndroidBiometric",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        // addDebugLog("📨 JavaScript 메시지: \(action)")

        switch action {
        case "authenticate":
            performBiometricAuthentication()

        case "isAvailable":
            checkBiometricAvailability()

        case "getFCMToken", "sendFCMToken":
            // 안드로이드와 동일: 실시간으로 UserDefaults에서 토큰 가져와서 전송
            sendFCMTokenToWeb()

        default:
            addDebugLog("⚠️ 알 수 없는 액션: \(action)")
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
        // Binary credential ID 생성 (32 bytes random) + device_id suffix
        let credentialIdBinary = [UInt8](repeating: 0, count: 32).map { _ in UInt8.random(in: 0...255) }
        let credentialIdWithDeviceId = "ios_\(deviceId)_\(timestamp)"

        // Challenge와 RpId 가져오기
        webView.evaluateJavaScript("window.passkeyChallenge") { [weak self] challengeResult, _ in
            guard let self = self else { return }

            self.webView.evaluateJavaScript("window.passkeyRpId") { rpIdResult, _ in
                let challenge = (challengeResult as? String) ?? "ios_biometric_challenge_\(timestamp)"
                let rpId = (rpIdResult as? String) ?? "sefra.kr"
                let origin = "https://\(rpId)"

                print("Challenge: \(challenge)")
                print("RpId: \(rpId)")
                print("Credential ID (string): \(credentialIdWithDeviceId)")
                print("Origin: \(origin)")

                // ClientDataJSON 생성
                let clientDataJSON = """
                {"type":"webauthn.create","challenge":"\(challenge)","origin":"\(origin)","crossOrigin":false,"ios_biometric":true}
                """
                let clientDataBase64 = clientDataJSON.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                // AttestationObject 생성 (더미)
                let attestationObject = "ios_biometric_attestation"
                let attestationBase64 = attestationObject.data(using: .utf8)?.base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "") ?? ""

                // rawId: binary credential ID를 base64url로 인코딩
                let credentialIdBase64 = Data(credentialIdBinary).base64EncodedString()
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "")

                // JavaScript 실행
                let javascript = """
                javascript:(function(){
                    try{
                        console.log('[BiometricAuth] JavaScript execution started');
                        var d={
                            id:'\(credentialIdWithDeviceId)',
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
                            id:'\(credentialIdWithDeviceId)',
                            rawId:'\(credentialIdBase64)',
                            type:'public-key',
                            response:{
                                clientDataJSON:'\(clientDataBase64)',
                                attestationObject:'\(attestationBase64)'
                            }
                        };
                        console.log('[BiometricAuth] RegData created:',JSON.stringify(regData));
                        console.log('[BiometricAuth] ========== WEBAUTHN PAYLOAD ==========');
                        console.log('[BiometricAuth] id:', regData.id);
                        console.log('[BiometricAuth] rawId:', regData.rawId);
                        console.log('[BiometricAuth] type:', regData.type);
                        console.log('[BiometricAuth] response.clientDataJSON:', regData.response.clientDataJSON);
                        console.log('[BiometricAuth] response.attestationObject:', regData.response.attestationObject);
                        console.log('[BiometricAuth] ====================================');
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
            // addDebugLog("⚠️ FCM 토큰이 아직 없음")
            return
        }

        // addDebugLog("📤 FCM 토큰 전송: \(token.prefix(20))...")
        // addDebugLog("📱 Device ID: \(deviceId)")

        let javascript = """
        (function() {
            var fcmToken = '\(token)';
            var deviceId = '\(deviceId)';

            if (fcmToken && fcmToken.length > 0) {
                console.log('FCM Token available:', fcmToken.substring(0, 30) + '...');
                console.log('Device ID:', deviceId);

                if (typeof onB4xDataUpdated === 'function') {
                    onB4xDataUpdated({
                        fcmToken: fcmToken,
                        deviceId: deviceId
                    });
                    console.log('✅ onB4xDataUpdated 함수 호출됨 (fcmToken + deviceId 전달)');
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

    // MARK: - Debug Log View
    private func setupDebugLogView() {
        // 컨테이너 뷰
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 8
        container.layer.masksToBounds = true
        view.addSubview(container)

        // 텍스트 뷰
        debugLogView = UITextView()
        debugLogView.backgroundColor = .clear
        debugLogView.textColor = .white
        debugLogView.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        debugLogView.isEditable = false
        debugLogView.isScrollEnabled = true
        container.addSubview(debugLogView)

        // 토글 버튼 (접기/펼치기)
        let toggleButton = UIButton(type: .system)
        toggleButton.setTitle("▼ Debug", for: .normal)
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        toggleButton.layer.cornerRadius = 4
        toggleButton.addTarget(self, action: #selector(toggleDebugViewSize), for: .touchUpInside)
        toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        container.addSubview(toggleButton)

        // 복사 버튼
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("📋 Copy", for: .normal)
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.backgroundColor = UIColor.blue.withAlphaComponent(0.7)
        copyButton.layer.cornerRadius = 4
        copyButton.addTarget(self, action: #selector(copyLogs), for: .touchUpInside)
        copyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        container.addSubview(copyButton)

        // 클리어 버튼
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("🗑️ Clear", for: .normal)
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.backgroundColor = UIColor.red.withAlphaComponent(0.7)
        clearButton.layer.cornerRadius = 4
        clearButton.addTarget(self, action: #selector(clearLogs), for: .touchUpInside)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        container.addSubview(clearButton)

        // Auto Layout
        container.translatesAutoresizingMaskIntoConstraints = false
        debugLogView.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        let heightConstraint = container.heightAnchor.constraint(equalToConstant: 220)
        heightConstraint.identifier = "debugHeight"

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            heightConstraint,

            debugLogView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            debugLogView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            debugLogView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            debugLogView.bottomAnchor.constraint(equalTo: toggleButton.topAnchor, constant: -4),

            toggleButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            toggleButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            toggleButton.heightAnchor.constraint(equalToConstant: 32),
            toggleButton.widthAnchor.constraint(equalToConstant: 80),

            copyButton.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor, constant: 4),
            copyButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            copyButton.heightAnchor.constraint(equalToConstant: 32),
            copyButton.widthAnchor.constraint(equalToConstant: 80),

            clearButton.leadingAnchor.constraint(equalTo: copyButton.trailingAnchor, constant: 4),
            clearButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            clearButton.heightAnchor.constraint(equalToConstant: 32),
            clearButton.widthAnchor.constraint(equalToConstant: 80)
        ])

        // 더블탭으로 토글
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleDebugViewAlpha))
        doubleTap.numberOfTapsRequired = 2
        debugLogView.addGestureRecognizer(doubleTap)
        debugLogView.isUserInteractionEnabled = true
    }

    @objc private func toggleDebugViewSize() {
        isDebugViewVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            if let container = self.debugLogView.superview {
                if self.isDebugViewVisible {
                    // 펼치기
                    if let heightConstraint = container.constraints.first(where: { $0.identifier == "debugHeight" }) {
                        heightConstraint.constant = 220
                    }
                } else {
                    // 접기
                    if let heightConstraint = container.constraints.first(where: { $0.identifier == "debugHeight" }) {
                        heightConstraint.constant = 50
                    }
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func toggleDebugViewAlpha() {
        // 더블탭: 투명도 조절
        let currentAlpha = self.debugLogView.alpha
        UIView.animate(withDuration: 0.2) {
            self.debugLogView.alpha = currentAlpha > 0.5 ? 0.2 : 1.0
        }
    }

    @objc private func copyLogs() {
        let logText = debugLogs.joined(separator: "\n")
        UIPasteboard.general.string = logText

        // 복사 성공 피드백
        let alert = UIAlertController(title: "✅ 복사됨", message: "로그가 클립보드에 복사되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func clearLogs() {
        debugLogs.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.debugLogView.text = ""
        }

        let alert = UIAlertController(title: "🗑️ 삭제됨", message: "모든 로그가 삭제되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"

        debugLogs.append(logMessage)
        if debugLogs.count > 100 {
            debugLogs.removeFirst()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let debugLogView = self.debugLogView else { return }
            debugLogView.text = self.debugLogs.joined(separator: "\n")
            if debugLogView.text.count > 0 {
                let bottom = NSRange(location: debugLogView.text.count - 1, length: 1)
                debugLogView.scrollRangeToVisible(bottom)
            }
        }

        // 콘솔에도 출력
        print(logMessage)
    }

}
