# Sefra iOS Native App

**Sefra iOS 네이티브 앱** - 안드로이드에서 포팅한 WebView 기반 iOS 앱

> ⚠️ **중요**: 이 저장소는 Flutter 프로젝트에서 iOS 네이티브 앱으로 전환되었습니다.
> Flutter 프로젝트는 [flutter-backup](https://github.com/zanoone/sefra/tree/flutter-backup) 브랜치에 백업되어 있습니다.

## 📱 앱 정보

- **앱 이름**: Sefra
- **Bundle ID**: sefra.kr
- **플랫폼**: iOS 13.0+
- **언어**: Swift 5.0
- **아키텍처**: Native iOS (UIKit + WKWebView)

## ✨ 주요 기능

- ✅ **WebView**: https://sefra.kr 로드
- ✅ **FCM 푸시 알림**: Firebase Cloud Messaging + APNs
- ✅ **생체인증**: Face ID / Touch ID (LocalAuthentication)
- ✅ **JavaScript Bridge**: 웹-네이티브 통신
- ✅ **본인인증**: URL Scheme 처리
- ✅ **Device ID**: identifierForVendor
- ✅ **Associated Domains**: Universal Links (applinks:sefra.kr)

## 📂 프로젝트 구조

```
sefra/
├── Sefra/
│   ├── Sefra.xcodeproj/         # Xcode 프로젝트
│   ├── Sefra/
│   │   ├── AppDelegate.swift           # FCM 초기화, 푸시 알림
│   │   ├── ViewController.swift        # WebView, 생체인증
│   │   ├── Info.plist                  # 앱 설정 및 권한
│   │   ├── Sefra.entitlements          # Push Notifications, Associated Domains
│   │   ├── GoogleService-Info.plist    # Firebase 설정
│   │   ├── Assets.xcassets/            # 앱 아이콘
│   │   └── Base.lproj/
│   │       └── LaunchScreen.storyboard
│   ├── Podfile                  # CocoaPods 의존성
│   └── exportOptions.plist      # IPA Export 설정
├── codemagic.yaml               # CI/CD 빌드 설정
├── APPLE_SETUP_GUIDE.md         # Apple Developer 설정 가이드
├── README_iOS.md                # 상세 개발 가이드
└── README.md                    # 이 파일
```

## 🚀 빠른 시작

### 로컬 개발 (Mac 필요)

```bash
# 1. 저장소 클론
git clone https://github.com/zanoone/sefra.git
cd sefra/Sefra

# 2. CocoaPods 설치
pod install

# 3. Xcode에서 프로젝트 열기
open Sefra.xcworkspace  # ⚠️ .xcodeproj가 아닌 .xcworkspace!
```

### Codemagic CI/CD 빌드

1. **Apple Developer Portal 설정**
   - Bundle ID `sefra.kr` 등록
   - Push Notifications, Associated Domains 활성화
   - 상세: [APPLE_SETUP_GUIDE.md](APPLE_SETUP_GUIDE.md)

2. **App Store Connect API Key 생성**
   - Users and Access → Keys
   - Key ID, Issuer ID, .p8 파일 다운로드

3. **Codemagic 환경 변수 설정**
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY`

4. **빌드 시작**
   - Workflow: `ios-release` (App Store) 또는 `ios-debug` (Development)

## 📋 필수 설정

### 1. Firebase 설정
- `GoogleService-Info.plist` 파일 포함 ✅
- Bundle ID: `sefra.kr`
- Firebase Console에서 APNs 인증 키 업로드 필요

### 2. Apple Developer 설정
- Bundle Identifier: `sefra.kr` 등록 필요
- Capabilities:
  - ✅ Push Notifications
  - ✅ Associated Domains (applinks:sefra.kr)

### 3. Codemagic 설정
- 환경 변수 3개 설정 필요
- App Store Connect API Key 필수

## 🔄 Flutter 프로젝트에서 전환

이 저장소는 Flutter 프로젝트에서 iOS 네이티브 앱으로 전환되었습니다.

### 변경 사항
- ✅ Flutter 코드 제거, iOS 네이티브로 전환
- ✅ CocoaPods로 Firebase 의존성 관리
- ✅ WKWebView 기반 구현
- ✅ JavaScript Bridge (AndroidBiometric → iOSBiometric)
- ✅ Flutter 프로젝트의 iOS 설정 반영

### Flutter 프로젝트 백업
Flutter 프로젝트가 필요한 경우:
```bash
git checkout flutter-backup
```

## 📚 문서

- [README_iOS.md](README_iOS.md) - 상세 개발 가이드
- [APPLE_SETUP_GUIDE.md](APPLE_SETUP_GUIDE.md) - Apple Developer 설정
- [codemagic.yaml](codemagic.yaml) - CI/CD 빌드 설정

## 🛠 기술 스택

- **언어**: Swift 5.0
- **UI**: UIKit, WKWebView
- **푸시 알림**: Firebase Messaging + APNs
- **생체인증**: LocalAuthentication (Face ID/Touch ID)
- **빌드**: Xcode 15+, CocoaPods
- **CI/CD**: Codemagic

## 🔐 보안

- ✅ 생체인증으로 보안 강화
- ✅ ATS (App Transport Security) 설정
- ✅ Firebase 암호화 통신
- ✅ 코드 난독화 지원

## 📱 Android 버전

Android 앱은 별도 저장소에서 관리됩니다:
- 패키지명: `com.sefra`
- 기술: Kotlin, Jetpack Compose, WebView

## 🤝 기여

이 프로젝트는 Android 앱을 iOS로 포팅한 버전입니다.

## 📧 문의

- 이메일: zanoone2@gmail.com
- GitHub Issues: https://github.com/zanoone/sefra/issues

## 📜 라이선스

Copyright © 2025 Sefra. All rights reserved.

---

**참고**: 이 프로젝트는 Flutter에서 네이티브 iOS로 전환되었습니다. Flutter 프로젝트가 필요한 경우 `flutter-backup` 브랜치를 확인하세요.
