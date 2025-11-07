# Sefra iOS App

안드로이드 앱에서 iOS로 포팅한 Sefra 네이티브 iOS 앱입니다.

## 주요 기능

- ✅ **WebView**: https://sefra.kr 웹사이트 로드
- ✅ **FCM 푸시 알림**: Firebase Cloud Messaging
- ✅ **생체인증**: Face ID / Touch ID
- ✅ **본인인증**: URL Scheme 처리
- ✅ **JavaScript Bridge**: 웹-네이티브 통신

## 프로젝트 구조

```
iosapp/
├── Sefra/
│   ├── Sefra.xcodeproj/        # Xcode 프로젝트 파일
│   ├── Sefra/
│   │   ├── AppDelegate.swift         # 앱 초기화, FCM 설정
│   │   ├── ViewController.swift      # WebView, 생체인증
│   │   ├── Info.plist                # 앱 권한 및 설정
│   │   ├── Sefra.entitlements        # Push Notifications, Associated Domains
│   │   ├── GoogleService-Info.plist  # Firebase 설정
│   │   ├── Assets.xcassets/          # 앱 아이콘 및 이미지
│   │   └── Base.lproj/
│   │       └── LaunchScreen.storyboard
│   ├── Podfile                 # CocoaPods 의존성
│   └── exportOptions.plist     # IPA Export 설정
├── codemagic.yaml              # Codemagic CI/CD 설정
├── APPLE_SETUP_GUIDE.md        # Apple Developer 설정 가이드
└── README.md                   # 이 파일
```

## 로컬 개발 환경 설정

### 1️⃣ 사전 요구사항

- macOS (Xcode는 macOS에서만 실행 가능)
- Xcode 14.0 이상
- CocoaPods 설치
- Apple Developer 계정

### 2️⃣ 설치

```bash
# 1. CocoaPods 설치 (설치되지 않은 경우)
sudo gem install cocoapods

# 2. 프로젝트 디렉토리로 이동
cd iosapp/Sefra

# 3. CocoaPods 의존성 설치
pod install

# ⚠️ 이제부터는 Sefra.xcworkspace 파일을 열어야 합니다!
# Sefra.xcodeproj가 아닌 Sefra.xcworkspace를 열어야 합니다.
```

### 3️⃣ Xcode에서 열기

```bash
open Sefra.xcworkspace
```

### 4️⃣ 프로젝트 설정

Xcode에서 다음 설정을 확인/수정하세요:

1. **Signing & Capabilities**
   - Team: Apple Developer 계정 선택
   - Bundle Identifier: `sefra.kr` (변경 가능)
   - Signing Certificate: 자동 또는 수동 설정

2. **Push Notifications 활성화**
   - Signing & Capabilities 탭에서 `+ Capability` 클릭
   - `Push Notifications` 추가

3. **Associated Domains (선택사항)**
   - Universal Links를 사용하려면 추가
   - `applinks:sefra.kr` 형식으로 추가

### 5️⃣ 빌드 및 실행

- 시뮬레이터 실행: `Cmd + R`
- 실제 디바이스: 디바이스 연결 후 `Cmd + R`

## Codemagic CI/CD 설정

### 1️⃣ Codemagic 계정 연동

1. https://codemagic.io 가입
2. GitHub/GitLab/Bitbucket 연동
3. 프로젝트 추가

### 2️⃣ Apple Developer 연동

Codemagic에서 다음 정보 설정:

1. **App Store Connect API Key**
   - Apple Developer Portal에서 API Key 생성
   - Key ID, Issuer ID, Private Key (.p8 파일) 다운로드
   - Codemagic 환경 변수에 추가:
     - `APP_STORE_CONNECT_KEY_IDENTIFIER`
     - `APP_STORE_CONNECT_ISSUER_ID`
     - `APP_STORE_CONNECT_PRIVATE_KEY`

2. **Signing Certificate & Provisioning Profile**
   - Codemagic가 자동으로 관리 (`fetch-signing-files` 사용)
   - 또는 수동으로 업로드

### 3️⃣ codemagic.yaml 수정

`iosapp/codemagic.yaml` 파일에서 다음 부분을 수정하세요:

```yaml
vars:
  APP_STORE_APPLE_ID: YOUR_APPLE_ID@example.com  # Apple Developer 이메일

publishing:
  email:
    recipients:
      - YOUR_EMAIL@example.com  # 빌드 알림 받을 이메일
```

### 4️⃣ 빌드 트리거

- **자동 빌드**: Git push 시 자동 실행
- **수동 빌드**: Codemagic 대시보드에서 "Start new build" 클릭

## Firebase 설정

### FCM APNs 인증 키 등록

1. **Apple Developer Portal**
   - Certificates, Identifiers & Profiles
   - Keys 메뉴에서 새 키 생성
   - Apple Push Notifications service (APNs) 체크
   - .p8 파일 다운로드

2. **Firebase Console**
   - 프로젝트 설정 > Cloud Messaging
   - Apple 앱 구성에서 APNs 인증 키 업로드
   - Key ID, Team ID 입력

## 앱 아이콘 추가

현재는 기본 아이콘이 설정되어 있습니다. 커스텀 아이콘을 추가하려면:

1. 아이콘 이미지 준비 (1024x1024 PNG)
2. https://appicon.co 에서 모든 사이즈 생성
3. Xcode에서 `Assets.xcassets/AppIcon.appiconset`에 이미지 드래그 앤 드롭

## 🔄 최신 업데이트 (Flutter 프로젝트 설정 반영)

기존 Flutter sefra 프로젝트의 iOS 설정을 반영하여 호환성을 개선했습니다:

### 변경사항
- ✅ **Info.plist**: `NSAllowsArbitraryLoads` 활성화 (WebView 호환성)
- ✅ **Sefra.entitlements**: Push Notifications + Associated Domains
- ✅ **exportOptions.plist**: App Store 배포 설정 추가
- ✅ **Podfile**: Static linkage + Firebase 헤더 오류 수정
- ✅ **추가 권한**: Tracking, Local Network, Camera 권한 추가

### Bundle Identifier 주의사항
- 현재 설정: `sefra.kr`
- Apple Developer Portal에서 먼저 Bundle ID를 등록해야 합니다
- 상세 가이드: [APPLE_SETUP_GUIDE.md](APPLE_SETUP_GUIDE.md)

## 안드로이드와의 차이점

| 기능 | Android | iOS |
|------|---------|-----|
| 생체인증 | BiometricPrompt | LocalAuthentication (Face ID/Touch ID) |
| 웹뷰 | WebView | WKWebView |
| JS Bridge | `JavascriptInterface` | `WKScriptMessageHandler` |
| 푸시 알림 | FCM 직접 사용 | FCM + APNs |
| 본인인증 | Intent 처리 | URL Scheme 처리 |
| Device ID | ANDROID_ID | identifierForVendor |
| 프레임워크 링크 | Dynamic | **Static** (Firebase 호환성) |

## JavaScript 인터페이스

웹에서 iOS 네이티브 기능 호출:

```javascript
// 생체인증 실행
window.iOSBiometric.authenticate();

// 생체인증 사용 가능 여부
const available = await window.iOSBiometric.isAvailable();

// FCM 토큰 가져오기
const token = await window.getFCMToken();

// Android 호환성 (동일한 코드 사용 가능)
window.AndroidBiometric.authenticate(); // iOS에서도 작동
```

## 배포

### TestFlight (베타 테스트)

1. Codemagic 빌드 성공 시 자동으로 TestFlight에 업로드됨
2. App Store Connect에서 테스터 초대
3. 테스터는 TestFlight 앱 설치 후 앱 다운로드

### App Store (정식 출시)

1. App Store Connect에서 앱 정보 입력
   - 스크린샷
   - 앱 설명
   - 키워드
   - 개인정보 처리방침 URL
2. TestFlight 빌드 중 하나를 선택
3. 심사 제출
4. 승인 후 출시

## 트러블슈팅

### 1. CocoaPods 설치 오류

```bash
# CocoaPods 캐시 삭제 후 재설치
pod cache clean --all
rm -rf Pods Podfile.lock
pod install
```

### 2. Signing 오류

- Xcode > Preferences > Accounts에서 Apple ID 로그인 확인
- Signing & Capabilities에서 Team 선택
- Bundle Identifier가 Apple Developer에 등록되어 있는지 확인

### 3. Firebase 초기화 오류

- `GoogleService-Info.plist` 파일이 Xcode 프로젝트에 추가되었는지 확인
- Bundle Identifier가 Firebase 콘솔의 iOS 앱 설정과 일치하는지 확인

### 4. 푸시 알림이 안 옴

- APNs 인증 키가 Firebase에 올바르게 등록되었는지 확인
- Info.plist에 `UIBackgroundModes` > `remote-notification` 설정 확인
- 실제 디바이스에서 테스트 (시뮬레이터는 푸시 알림 미지원)

### 5. 생체인증이 작동하지 않음

- Info.plist에 `NSFaceIDUsageDescription` 설정 확인
- 시뮬레이터: Features > Face ID / Touch ID > Enrolled 설정

## 추가 자료

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Codemagic Documentation](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)

## 라이선스

Copyright © 2025 Sefra. All rights reserved.
