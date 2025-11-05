# TestFlight 자동 배포 설정 가이드

## 현재 상황
- ✅ iOS 앱 빌드 성공 (`--no-codesign`)
- ❌ TestFlight 배포 실패 (인증서 없음)

**에러:**
```
No valid code signing certificates were found
```

---

## 해결 방법: Codemagic Automatic Code Signing (가장 쉬움)

### 1️⃣ Codemagic에서 Apple Developer 연결

**Codemagic 대시보드:**
```
1. https://codemagic.io/apps 접속
2. Sefra 프로젝트 클릭
3. Settings (톱니바퀴) → Code signing identities
4. iOS code signing → Automatic code signing
```

**필요한 정보:**
- Apple Developer 계정 (Apple ID + 비밀번호)
- Bundle ID: `com.sefra.sefraFlutter`
- App-specific password 생성 필요

---

### 2️⃣ Apple App-Specific Password 생성

**Apple ID 설정:**
```
1. https://appleid.apple.com 접속
2. Sign-in and Security → App-Specific Passwords
3. "Generate password..." 클릭
4. 이름: "Codemagic" 입력
5. 생성된 비밀번호 복사 (예: xxxx-xxxx-xxxx-xxxx)
```

---

### 3️⃣ Codemagic에 인증서 설정

**Automatic code signing 설정:**
```
Apple ID: (Apple Developer 계정 이메일)
App-specific password: (2️⃣에서 생성한 비밀번호)
Team: (Apple Developer Team 선택)
Bundle identifier: com.sefra.sefraFlutter
```

**Codemagic가 자동으로 처리:**
- ✅ Distribution Certificate 생성
- ✅ Provisioning Profile 생성
- ✅ 코드사인
- ✅ TestFlight 업로드

---

### 4️⃣ App Store Connect API 환경변수 추가

**Codemagic → Environment variables에 추가:**

| Variable name | Value | Secure |
|--------------|-------|--------|
| `APP_STORE_CONNECT_API_KEY_ID` | `654L7W8MGA` | ✅ |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect에서 확인 필요 | ✅ |
| `APP_STORE_CONNECT_API_KEY` | 아래 base64 값 | ✅ |

**APP_STORE_CONNECT_API_KEY 값:**
```
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEJIa3dkd0lCQVFRZ2tHRUhEQTZNNUh0cmNTbmQKQ3RSMDZEZ2NUU1dpYzE5SzZJYk4rem8ybFZ1Z0NnWUlLb1pJemowREFRZWhSQU5DQUFRNUxKOXFtYjJ4UnhJego5eEEzaWM1bHF2SC9yNUp3K2I3VlErR2JoUDUwZmpBVlBoT3hCMDJvdER6Rk51dGtvUWxlZlFIQWlsaTlSZnhyClg4dE00Y1Z4Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0=
```

**Issuer ID 찾는 방법:**
```
1. https://appstoreconnect.apple.com
2. Users and Access → Keys
3. "Issuer ID" 복사 (UUID 형식)
```

---

### 5️⃣ codemagic.yaml 수정

**현재:** TestFlight 배포 부분이 주석 처리됨

**수정 필요:** `deploy-testflight` job의 주석을 제거하고 활성화

**또는 더 간단하게:**

`codemagic.yaml`을 다음과 같이 수정:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      vars:
        XCODE_WORKSPACE: "Runner.xcworkspace"
        XCODE_SCHEME: "Runner"
        BUNDLE_ID: "com.sefra.sefraFlutter"
        GOOGLE_SERVICE_INFO_PLIST: Encrypted(...)
      flutter: stable
      xcode: latest
      cocoapods: default

    scripts:
      - name: Set up Firebase configuration
        script: |
          echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > ios/Runner/GoogleService-Info.plist
      - name: Get Flutter packages
        script: |
          flutter packages pub get
      - name: Clean and update pods
        script: |
          cd ios
          pod deintegrate || true
          rm -rf Pods Podfile.lock
          pod install --repo-update
      - name: Flutter build IPA
        script: |
          flutter build ipa --release --export-options-plist=/Users/builder/export_options.plist

    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log

    publishing:
      email:
        recipients:
          - zanoone2@gmail.com
        notify:
          success: true
          failure: true
      app_store_connect:
        api_key: $APP_STORE_CONNECT_API_KEY
        key_id: $APP_STORE_CONNECT_API_KEY_ID
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
        submit_to_testflight: true
```

---

## 전체 순서 요약

### ✅ 체크리스트

**Apple 계정 설정:**
- [ ] App-specific password 생성
- [ ] App Store Connect에서 Issuer ID 확인

**Codemagic 설정:**
- [ ] Automatic code signing 활성화
- [ ] Apple ID + App-specific password 입력
- [ ] 환경변수 3개 추가 (API Key ID, Issuer ID, API Key)

**코드 수정:**
- [ ] `codemagic.yaml` 수정 (TestFlight 배포 활성화)
- [ ] GitHub push

**빌드:**
- [ ] Codemagic에서 빌드 시작
- [ ] 성공 시 자동으로 TestFlight 업로드됨

---

## 예상 시간

- **Apple 설정:** 10분
- **Codemagic 설정:** 10분
- **빌드 + 업로드:** 10분

**총 30분이면 TestFlight 완료**

---

## 문제 해결

### Q: "No code signing certificates" 에러
**A:** Automatic code signing에서 Apple ID 다시 확인

### Q: "Invalid Issuer ID" 에러
**A:** App Store Connect → Users and Access → Keys에서 Issuer ID 다시 복사

### Q: 빌드는 성공했는데 TestFlight에 안 올라감
**A:** `app_store_connect` 섹션이 활성화되었는지 확인

---

## 참고 링크

- **Codemagic 공식 가이드:** https://docs.codemagic.io/yaml-publishing/app-store-connect/
- **Apple Developer:** https://developer.apple.com
- **App Store Connect:** https://appstoreconnect.apple.com

---

**작성일:** 2025-11-05
**GitHub:** https://github.com/zanoone/sefra
