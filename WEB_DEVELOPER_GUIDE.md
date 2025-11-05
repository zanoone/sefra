# 웹 개발자님께 전달 사항

안녕하세요! Sefra Flutter 앱의 FCM 설정과 GitHub Actions 자동 빌드를 완료했습니다.

---

## 🎯 지금 바로 해야 할 일

### 1️⃣ GitHub Secret 등록 (필수)

GitHub Actions가 작동하려면 **반드시** 다음 Secret을 등록해야 합니다:

**등록 방법:**
1. https://github.com/zanoone/sefra 접속
2. **Settings** → **Secrets and variables** → **Actions** 클릭
3. **"New repository secret"** 클릭
4. 아래 정보 입력:

**Secret 정보:**

**Name:** `GOOGLE_SERVICE_INFO_PLIST`

**Value:** (아래 전체 복사)
```
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0IFBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo8ZGljdD4KCTxrZXk+QVBJX0tFWTwva2V5PgoJPHN0cmluZz5BSXphU3lBa2RiX2g4dnVBM1Q2TVRCbkFGTGp5WEI2R0pZMmdKa2s8L3N0cmluZz4KCTxrZXk+R0NNX1NFTkRFUl9JRDwva2V5PgoJPHN0cmluZz40OTA5MDY4ODI1ODE8L3N0cmluZz4KCTxrZXk+UExJU1RfVkVSU0lPTjwva2V5PgoJPHN0cmluZz4xPC9zdHJpbmc+Cgk8a2V5PkJVTkRMRV9JRDwva2V5PgoJPHN0cmluZz5jb20uc2VmcmEuc2VmcmFGbHV0dGVyPC9zdHJpbmc+Cgk8a2V5PlBST0pFQ1RfSUQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGI8L3N0cmluZz4KCTxrZXk+U1RPUkFHRV9CVUNLRVQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGIuZmlyZWJhc2VzdG9yYWdlLmFwcDwvc3RyaW5nPgoJPGtleT5JU19BRFNfRU5BQkxFRDwva2V5PgoJPGZhbHNlPjwvZmFsc2U+Cgk8a2V5PklTX0FOQUxZVElDU19FTkFCTEVEPC9rZXk+Cgk8ZmFsc2U+PC9mYWxzZT4KCTxrZXk+SVNfQVBQSU5WSVRFX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfR0NNX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfU0lHTklOX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+R09PR0xFX0FQUF9JRDwva2V5PgoJPHN0cmluZz4xOjQ5MDkwNjg4MjU4MTppb3M6Y2E2MzgzNzJhZjU2MmRiZjY2NzQxYzwvc3RyaW5nPgo8L2RpY3Q+CjwvcGxpc3Q+
```

5. **"Add secret"** 클릭

---

### 2️⃣ GitHub Actions 워크플로우 파일 추가

**⚠️ 중요:** 제가 만든 워크플로우 파일이 권한 문제로 push되지 않았습니다.

**해결 방법 (택 1):**

#### 방법 A: 웹에서 직접 추가 (가장 빠름)

1. https://github.com/zanoone/sefra 접속
2. **".github/workflows"** 폴더 생성
3. **"ios-build.yml"** 파일 생성
4. 아래 내용 전체 복사/붙여넣기:

<details>
<summary><b>📄 ios-build.yml 파일 내용 (클릭하여 펼치기)</b></summary>

```yaml
name: iOS Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-ios:
    runs-on: macos-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.7'
        channel: 'stable'
        cache: true

    - name: Install Flutter dependencies
      run: flutter pub get

    - name: Setup GoogleService-Info.plist
      env:
        GOOGLE_SERVICE_INFO_PLIST: ${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}
      run: |
        echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > ios/Runner/GoogleService-Info.plist

    - name: Install CocoaPods dependencies
      run: |
        cd ios
        pod install

    - name: Build iOS (Debug)
      run: |
        flutter build ios --debug --no-codesign

    - name: Upload build artifacts
      uses: actions/upload-artifact@v4
      if: success()
      with:
        name: ios-build
        path: build/ios/iphoneos/Runner.app
        retention-days: 7
```
</details>

#### 방법 B: Personal Access Token 권한 수정

현재 토큰에 `workflow` scope가 없습니다.

1. https://github.com/settings/tokens 접속
2. 현재 토큰 수정 또는 새 토큰 생성
3. **`workflow`** scope 체크
4. 토큰 저장 후 다시 push

---

### 3️⃣ 빌드 테스트

Secret과 워크플로우 파일 추가 후:

1. GitHub Repository → **Actions** 탭
2. **"iOS Build"** 워크플로우 선택
3. **"Run workflow"** → **"Run workflow"** 클릭
4. 빌드 진행 상황 확인

---

## 📋 완료된 작업

✅ **FCM (Firebase Cloud Messaging) 설정 완료**
- iOS AppDelegate에 Firebase 초기화 추가
- 푸시 알림 권한 요청 코드 추가
- FCM 토큰 자동 수집 및 갱신
- 포그라운드/백그라운드 메시지 핸들링

✅ **iOS 네이티브 설정**
- GoogleService-Info.plist 추가 (iOS/Runner 폴더)
- Podfile 생성 (CocoaPods 의존성 관리)
- .gitignore 업데이트 (민감한 파일 보호)

✅ **Flutter 앱 기능**
- WebView (https://test.sefra.com)
- Biometric 인증 (Face ID/Touch ID)
- FCM 푸시 알림
- JavaScript Bridge (웹 ↔ 네이티브 통신)
- Device ID 수집

✅ **GitHub Actions 워크플로우 준비**
- iOS 자동 빌드 설정
- Flutter 3.35.7 사용
- CocoaPods 자동 설치
- Build artifact 업로드

---

## 📱 앱 정보

- **iOS Bundle ID**: `com.sefra.sefraFlutter`
- **Android Application ID**: `kr.sefra`
- **Firebase Project**: `sefra-5f70b`
- **FCM Sender ID**: `490906882581`
- **WebView URL**: https://test.sefra.com

---

## 🔍 확인 사항

### GitHub Repository 공개 여부
- ✅ 현재 **공개 저장소**로 설정됨
- ✅ 민감한 정보는 모두 `.gitignore`로 보호됨
  - `GoogleService-Info.plist`
  - `AuthKey_*.p8`
  - `google-services.json`

### 로컬 개발 시 필요한 파일
로컬에서 빌드하려면 다음 파일을 직접 추가해야 합니다:
- `ios/Runner/GoogleService-Info.plist`
- (Android용) `android/app/google-services.json`

이 파일들은 GitHub에 올라가지 않으므로, Firebase Console에서 다운로드하거나 별도로 전달받아야 합니다.

---

## 🚀 다음 단계 (선택 사항)

### TestFlight 자동 배포 설정

TestFlight에 자동 배포하려면:

1. **추가 GitHub Secrets 등록**
   - `APPLE_CERTIFICATE_P12`: Distribution Certificate
   - `APPLE_CERTIFICATE_PASSWORD`: Certificate 비밀번호
   - `PROVISIONING_PROFILE`: Provisioning Profile
   - `APP_STORE_CONNECT_API_KEY_ID`: `654L7W8MGA`
   - `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect에서 확인
   - `APP_STORE_CONNECT_API_KEY`: (아래 값 사용)

**APP_STORE_CONNECT_API_KEY 값:**
```
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEJIa3dkd0lCQVFRZ2tHRUhEQTZNNUh0cmNTbmQKQ3RSMDZEZ2NUU1dpYzE5SzZJYk4rem8ybFZ1Z0NnWUlLb1pJemowREFRZWhSQU5DQUFRNUxKOXFtYjJ4UnhJego5eEEzaWM1bHF2SC9yNUp3K2I3VlErR2JoUDUwZmpBVlBoT3hCMDJvdER6Rk51dGtvUWxlZlFIQWlsaTlSZnhyClg4dE00Y1Z4Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0=
```

2. **워크플로우 파일에서 TestFlight 배포 활성화**
   - `.github/workflows/ios-build.yml` 파일 열기
   - `# TestFlight 배포` 주석 부분 활성화 (주석 제거)

---

## ❓ 문제 해결

### Q: "GOOGLE_SERVICE_INFO_PLIST secret not found" 에러
**A:** GitHub Secrets에 Secret이 제대로 등록되지 않았습니다. 위의 1️⃣ 단계를 다시 확인하세요.

### Q: Pod install 실패
**A:** Podfile이 제대로 커밋되었는지 확인하세요. 또는 Actions 로그에서 구체적인 에러 메시지를 확인하세요.

### Q: 빌드는 성공했는데 FCM이 작동하지 않습니다
**A:**
1. Firebase Console에서 APNs 인증키가 등록되었는지 확인
2. 실제 iOS 기기에서 테스트 (시뮬레이터는 푸시 알림 불가)
3. 앱에서 알림 권한이 허용되었는지 확인

---

## 📞 문의 사항

추가 질문이나 문제가 있으면 언제든지 연락주세요!

**참고 문서:**
- `SETUP_GUIDE.md`: 전체 설정 가이드
- `.github/workflows/ios-build.yml`: GitHub Actions 워크플로우

---

**준비 완료!** 🎉

GitHub Secret만 등록하고 워크플로우 파일만 추가하면 바로 자동 빌드가 시작됩니다!

**작성일**: 2025-11-05
