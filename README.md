# Sefra iOS

Android 앱을 iOS 네이티브 앱으로 변환한 프로젝트입니다.

## 주요 기능

- **WKWebView**: sefra.kr 웹사이트 로드
- **생체인증**: Face ID / Touch ID 지원
- **Firebase Cloud Messaging**: 푸시 알림
- **JavaScript Bridge**: 웹과 네이티브 앱 간 통신

## 기술 스택

- **언어**: Swift 5.0
- **UI 프레임워크**: UIKit
- **최소 iOS 버전**: iOS 14.0
- **의존성 관리**: CocoaPods
- **CI/CD**: Codemagic

## 프로젝트 구조

```
SefraiOS/
├── SefraiOS/
│   ├── AppDelegate.swift          # 앱 생명주기, FCM 초기화
│   ├── ViewController.swift       # WebView, 생체인증 구현
│   ├── Info.plist                 # 앱 설정 및 권한
│   ├── GoogleService-Info.plist   # Firebase 설정
│   ├── LaunchScreen.storyboard    # 런치 스크린
│   └── Assets.xcassets/           # 앱 아이콘 및 리소스
├── SefraiOS.xcodeproj/            # Xcode 프로젝트
├── Podfile                        # CocoaPods 의존성
├── codemagic.yaml                 # Codemagic 빌드 설정
└── README.md                      # 이 파일
```

## 설치 및 실행

### 1. 사전 요구사항

- macOS 13.0 이상
- Xcode 15.0 이상
- CocoaPods 설치
- Apple Developer 계정

### 2. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. Android 프로젝트와 동일한 Firebase 프로젝트 선택
3. "프로젝트 설정" → "일반" → "iOS 앱 추가" 클릭
4. iOS 번들 ID 입력: `com.sefra`
5. `GoogleService-Info.plist` 파일 다운로드
6. 다운로드한 파일을 `SefraiOS/SefraiOS/GoogleService-Info.plist`로 교체

### 3. CocoaPods 의존성 설치

```bash
cd SefraiOS
pod install
```

### 4. Xcode에서 프로젝트 열기

```bash
open SefraiOS.xcworkspace
```

⚠️ **중요**: `.xcodeproj`가 아닌 `.xcworkspace`를 열어야 합니다!

### 5. 시뮬레이터 실행

1. Xcode에서 시뮬레이터 선택 (예: iPhone 15 Pro)
2. `Cmd + R`로 빌드 및 실행

## Codemagic 빌드 설정

### 1. Codemagic 환경 변수 설정

Codemagic 프로젝트 설정에서 다음 환경 변수를 추가하세요:

```
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_IDENTIFIER
APP_STORE_CONNECT_PRIVATE_KEY
CERTIFICATE_PRIVATE_KEY
```

### 2. 빌드 트리거

- `main` 또는 `develop` 브랜치에 푸시
- Pull Request 생성

### 3. 빌드 결과

- `.ipa` 파일이 생성됩니다
- TestFlight에 자동으로 업로드됩니다

## Android vs iOS 주요 차이점

| 기능 | Android | iOS |
|------|---------|-----|
| WebView | `android.webkit.WebView` | `WKWebView` |
| 생체인증 | `BiometricPrompt` | `LocalAuthentication` |
| JavaScript Bridge | `addJavascriptInterface` | `WKScriptMessageHandler` |
| FCM | `FirebaseMessaging` | `FirebaseMessaging` (iOS SDK) |
| 푸시 알림 | FCM Token | APNs Token + FCM Token |
| 권한 요청 | `AndroidManifest.xml` | `Info.plist` |

## 생체인증 동작 방식

1. 웹페이지에서 `window.webkit.messageHandlers.AndroidBiometric.postMessage({action: 'authenticate'})` 호출
2. iOS 네이티브에서 Face ID/Touch ID 프롬프트 표시
3. 인증 성공 시 PassKey 데이터 생성
4. JavaScript 콜백 함수로 결과 전달:
   - `window.onBiometricResult(success, message, data)`
   - `window.onBiometricLoginSuccess(data)`

## FCM 푸시 알림

### 토큰 관리

- 앱 실행 시 FCM 토큰을 자동으로 가져옵니다
- `UserDefaults`에 저장됩니다
- 웹페이지에서 `window.getFCMToken()` 또는 `window.sendFCMTokenToServer()`로 접근 가능

### 알림 수신

- **포그라운드**: 배너, 소리, 뱃지 표시
- **백그라운드**: 시스템 알림 표시
- **알림 탭**: `target_url`로 이동

## 개발 시 주의사항

### 1. 앱 아이콘

`SefraiOS/Assets.xcassets/AppIcon.appiconset/`에 다음 크기의 이미지를 추가하세요:
- 20x20 @2x, @3x
- 29x29 @2x, @3x
- 40x40 @2x, @3x
- 60x60 @2x, @3x
- 1024x1024 @1x (App Store)

### 2. 번들 ID 변경

번들 ID를 변경하려면:
1. Xcode에서 프로젝트 설정 열기
2. "Signing & Capabilities" 탭
3. "Bundle Identifier" 변경
4. Firebase Console에서 iOS 앱 번들 ID도 동일하게 변경

### 3. 인증서 및 프로비저닝 프로파일

- Apple Developer 계정 필요
- Automatic Signing 또는 Manual Signing 선택
- Codemagic 빌드 시 인증서 업로드 필요

## 디버깅

### WebView 디버깅

1. Safari 열기
2. "개발자" → "시뮬레이터" → "SefraiOS" 선택
3. 웹 인스펙터에서 콘솔 로그 확인

### Xcode 콘솔

- 네이티브 코드의 `print()` 로그 확인
- JavaScript → 네이티브 메시지 확인

## 트러블슈팅

### CocoaPods 오류

```bash
pod deintegrate
pod install --repo-update
```

### Firebase 연결 오류

- `GoogleService-Info.plist` 파일이 올바른 위치에 있는지 확인
- Firebase Console에서 iOS 앱이 추가되었는지 확인

### 생체인증 실패

- 시뮬레이터에서는 Face ID/Touch ID를 "Features" → "Face ID" → "Enrolled"로 활성화
- Info.plist에 `NSFaceIDUsageDescription` 추가 확인

## 라이센스

이 프로젝트는 원본 Android 프로젝트와 동일한 라이센스를 따릅니다.

## 문의

문제가 발생하거나 질문이 있으시면 이슈를 등록해주세요.
