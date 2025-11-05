# Sefra Flutter - Setup Guide

## 📱 프로젝트 정보

- **Bundle ID (iOS)**: `com.sefra.sefraFlutter`
- **Application ID (Android)**: `kr.sefra`
- **GitHub Repository**: https://github.com/zanoone/sefra

---

## 🔐 GitHub Secrets 설정 (필수)

GitHub Actions가 작동하려면 아래 Secrets를 설정해야 합니다.

**설정 방법**: GitHub Repository → Settings → Secrets and variables → Actions → New repository secret

### 1️⃣ 필수 Secret

| Secret 이름 | 값 | 설명 |
|------------|---|-----|
| `GOOGLE_SERVICE_INFO_PLIST` | 아래 참조 | Firebase iOS 설정 파일 (base64) |

**GOOGLE_SERVICE_INFO_PLIST 값:**
```
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0IFBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo8ZGljdD4KCTxrZXk+QVBJX0tFWTwva2V5PgoJPHN0cmluZz5BSXphU3lBa2RiX2g4dnVBM1Q2TVRCbkFGTGp5WEI2R0pZMmdKa2s8L3N0cmluZz4KCTxrZXk+R0NNX1NFTkRFUl9JRDwva2V5PgoJPHN0cmluZz40OTA5MDY4ODI1ODE8L3N0cmluZz4KCTxrZXk+UExJU1RfVkVSU0lPTjwva2V5PgoJPHN0cmluZz4xPC9zdHJpbmc+Cgk8a2V5PkJVTkRMRV9JRDwva2V5PgoJPHN0cmluZz5jb20uc2VmcmEuc2VmcmFGbHV0dGVyPC9zdHJpbmc+Cgk8a2V5PlBST0pFQ1RfSUQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGI8L3N0cmluZz4KCTxrZXk+U1RPUkFHRV9CVUNLRVQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGIuZmlyZWJhc2VzdG9yYWdlLmFwcDwvc3RyaW5nPgoJPGtleT5JU19BRFNfRU5BQkxFRDwva2V5PgoJPGZhbHNlPjwvZmFsc2U+Cgk8a2V5PklTX0FOQUxZVElDU19FTkFCTEVEPC9rZXk+Cgk8ZmFsc2U+PC9mYWxzZT4KCTxrZXk+SVNfQVBQSU5WSVRFX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfR0NNX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfU0lHTklOX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+R09PR0xFX0FQUF9JRDwva2V5PgoJPHN0cmluZz4xOjQ5MDkwNjg4MjU4MTppb3M6Y2E2MzgzNzJhZjU2MmRiZjY2NzQxYzwvc3RyaW5nPgo8L2RpY3Q+CjwvcGxpc3Q+
```

---

### 2️⃣ TestFlight 배포용 Secrets (선택 사항)

TestFlight에 자동 배포하려면 추가로 필요합니다:

| Secret 이름 | 설명 |
|------------|-----|
| `APPLE_CERTIFICATE_P12` | Apple Distribution Certificate (p12 파일, base64 인코딩) |
| `APPLE_CERTIFICATE_PASSWORD` | p12 파일 비밀번호 |
| `PROVISIONING_PROFILE` | Provisioning Profile (mobileprovision 파일, base64 인코딩) |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API Key (p8 파일 내용, base64 인코딩) |

**APP_STORE_CONNECT_API_KEY 값 (AuthKey_654L7W8MGA.p8):**
```
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEJIa3dkd0lCQVFRZ2tHRUhEQTZNNUh0cmNTbmQKQ3RSMDZEZ2NUU1dpYzE5SzZJYk4rem8ybFZ1Z0NnWUlLb1pJemowREFRZWhSQU5DQUFRNUxKOXFtYjJ4UnhJego5eEEzaWM1bHF2SC9yNUp3K2I3VlErR2JoUDUwZmpBVlBoT3hCMDJvdER6Rk51dGtvUWxlZlFIQWlsaTlSZnhyClg4dE00Y1Z4Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0=
```

**API Key 정보:**
- Key ID: `654L7W8MGA` (APP_STORE_CONNECT_API_KEY_ID에 입력)
- Issuer ID는 App Store Connect에서 확인 필요

---

## 🚀 GitHub Actions 사용법

### 자동 빌드 트리거

다음 경우에 자동으로 빌드가 시작됩니다:
- `main` 브랜치에 push할 때
- Pull Request 생성 시
- GitHub Actions 탭에서 수동 실행 (workflow_dispatch)

### 수동 빌드 실행

1. GitHub Repository → Actions 탭
2. "iOS Build" 워크플로우 선택
3. "Run workflow" 버튼 클릭
4. `main` 브랜치 선택 후 실행

---

## 📋 로컬 개발 환경 설정

프로젝트를 클론한 후 다음 파일들이 **반드시** 필요합니다:

### iOS 개발
```bash
# 1. GoogleService-Info.plist를 iOS/Runner 폴더에 추가
# (GitHub Secrets의 base64 값을 디코딩하거나 Firebase Console에서 다운로드)

# 2. CocoaPods 의존성 설치
cd ios
pod install

# 3. Flutter 빌드
cd ..
flutter build ios
```

### Android 개발 (향후)
```bash
# google-services.json 파일이 필요함 (Firebase Console에서 다운로드)
# android/app/google-services.json 위치에 추가
```

---

## 🔥 Firebase 설정 정보

- **프로젝트 ID**: `sefra-5f70b`
- **iOS Bundle ID**: `com.sefra.sefraFlutter`
- **FCM Sender ID**: `490906882581`
- **Google App ID**: `1:490906882581:ios:ca638372af562dbf66741c`

---

## 📱 기능

- ✅ WebView (https://test.sefra.com)
- ✅ Biometric Authentication (Face ID / Touch ID)
- ✅ Firebase Cloud Messaging (FCM 푸시 알림)
- ✅ Device ID 수집
- ✅ JavaScript Bridge (웹 ↔ 네이티브 통신)

---

## 🛠️ 웹 개발자 전달 사항

### 1. GitHub Secrets 등록 필수
위의 `GOOGLE_SERVICE_INFO_PLIST` 값을 복사하여 GitHub Secrets에 등록해주세요.

**등록 방법:**
```
1. https://github.com/zanoone/sefra 접속
2. Settings → Secrets and variables → Actions
3. "New repository secret" 클릭
4. Name: GOOGLE_SERVICE_INFO_PLIST
5. Secret: 위의 base64 값 전체 복사/붙여넣기
6. "Add secret" 클릭
```

### 2. GitHub Repository 공개 여부 확인
- 현재 공개 저장소로 설정되어 있음
- 민감한 정보 (Firebase 설정, Apple 인증키)는 `.gitignore`로 보호됨

### 3. TestFlight 배포 설정 (선택 사항)
- TestFlight 자동 배포가 필요하면 `.github/workflows/ios-build.yml` 파일의 주석 처리된 `deploy-testflight` job을 활성화
- 추가 Secrets 등록 필요 (위의 2️⃣ 참조)

### 4. 빌드 확인
- GitHub Actions 탭에서 빌드 상태 확인 가능
- 빌드 실패 시 로그 확인하여 문제 해결

---

## 📞 문제 해결

### Q: GitHub Actions 빌드가 실패합니다
A:
1. GitHub Secrets에 `GOOGLE_SERVICE_INFO_PLIST`가 제대로 등록되었는지 확인
2. base64 값 전체가 복사되었는지 확인 (공백 없이)
3. Actions 탭에서 빌드 로그 확인

### Q: FCM 푸시 알림이 작동하지 않습니다
A:
1. Firebase Console에서 APNs 인증 키가 등록되었는지 확인
2. iOS 기기에서 알림 권한이 허용되었는지 확인
3. Xcode에서 Push Notifications capability가 활성화되었는지 확인

### Q: 로컬에서 빌드가 안됩니다
A:
1. `ios/Runner/GoogleService-Info.plist` 파일이 있는지 확인
2. `cd ios && pod install` 실행
3. `flutter pub get` 실행

---

**작성일**: 2025-11-05
**작성자**: Claude Code Assistant
