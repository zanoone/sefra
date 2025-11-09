# Apple Developer 연결 가이드

Apple Developer 계정을 구매했으니, Codemagic 및 App Store Connect와 연결하는 방법을 안내합니다.

## ✅ 완료된 작업

- [x] 번들 ID 변경: `sefra.kr`
- [x] GoogleService-Info.plist 설정 완료
- [x] CocoaPods 의존성 설치 (Firebase 10.29.0)
- [x] Xcode 빌드 성공 확인

## 1. Apple Developer Portal 설정

### 1.1 App ID 생성

1. https://developer.apple.com/account 로그인
2. **Certificates, Identifiers & Profiles** 선택
3. **Identifiers** → **+** 버튼 클릭
4. **App IDs** 선택 → Continue
5. 설정:
   ```
   Description: Sefra iOS
   Bundle ID: sefra.kr (Explicit)
   Capabilities:
   ✓ Push Notifications
   ```
6. **Register** 클릭

### 1.2 APNs 인증 키 생성 (푸시 알림용)

1. **Keys** → **+** 버튼
2. 설정:
   ```
   Key Name: Sefra APNs Key
   ✓ Apple Push Notifications service (APNs)
   ```
3. **Continue** → **Register**
4. **Download** (⚠️ 한 번만 가능!)
   - `.p8` 파일 저장
   - **Key ID** 복사 (예: `ABC123XY12`)
   - 페이지 상단의 **Issuer ID** 복사

## 2. App Store Connect 설정

### 2.1 API Key 생성 (Codemagic 연동용)

1. https://appstoreconnect.apple.com/ 로그인
2. **Users and Access** → **Keys** 탭
3. **+** 버튼 (Generate API Key)
4. 설정:
   ```
   Name: Codemagic CI/CD
   Access: App Manager
   ```
5. **Generate** 클릭
6. `.p8` 파일 다운로드 (⚠️ 한 번만 가능!)
7. 정보 저장:
   - **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Key ID**: `XXXXXXXXXX`
   - **Private Key**: `.p8` 파일 내용 전체

### 2.2 앱 생성

1. **My Apps** → **+** → **New App**
2. 설정:
   ```
   Platform: iOS
   Name: Sefra
   Primary Language: Korean
   Bundle ID: sefra.kr
   SKU: sefra-ios-2024
   User Access: Full Access
   ```
3. **Create** 클릭

## 3. Codemagic 환경 변수 설정

### 3.1 Codemagic 프로젝트 생성

1. https://codemagic.io 로그인
2. **Add application** 클릭
3. GitHub/GitLab에서 `SefraiOS` 프로젝트 선택
4. **Set up build** 클릭

### 3.2 환경 변수 추가

**Settings** → **Environment variables**로 이동하여 추가:

#### Required Variables (필수)

| 변수 이름 | 값 | 비고 |
|----------|---|------|
| `APP_STORE_CONNECT_ISSUER_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | App Store Connect API Issuer ID |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | `XXXXXXXXXX` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | `.p8` 파일 전체 내용 | -----BEGIN PRIVATE KEY----- 부터 -----END PRIVATE KEY----- 까지 |

**APP_STORE_CONNECT_PRIVATE_KEY 설정 방법:**
```bash
# Mac에서 .p8 파일 열기
cat AuthKey_XXXXXXXXXX.p8

# 출력된 내용 전체를 복사해서 Codemagic에 붙여넣기
# -----BEGIN PRIVATE KEY----- 포함
```

### 3.3 Code Signing 설정 (자동 서명 권장)

**Settings** → **Code signing identities** → **iOS code signing**

**방법 1: Automatic (권장)**
1. **Enable automatic code signing** 선택
2. Apple ID 입력
3. App-specific password 생성:
   - https://appleid.apple.com/
   - **Sign-in and Security** → **App-specific passwords**
   - **Generate password...**
   - 생성된 비밀번호를 Codemagic에 입력

**방법 2: Manual (고급)**
- Distribution Certificate (`.p12`) 업로드
- Provisioning Profile (`.mobileprovision`) 업로드
- `CERTIFICATE_PRIVATE_KEY` 환경 변수 설정

## 4. Git 저장소 설정

### 4.1 Git 초기화 및 커밋

```bash
cd /Users/admin/SefraiOS

# Git 저장소 초기화 (아직 안 했다면)
git init

# .gitignore 확인 (이미 생성되어 있음)
cat .gitignore

# 파일 추가
git add .
git commit -m "Initial iOS app setup

- WKWebView with sefra.kr
- Face ID / Touch ID authentication
- Firebase Cloud Messaging
- Bundle ID: sefra.kr
- Firebase 10.29.0
"

# GitHub/GitLab 저장소 생성 후 연결
git remote add origin https://github.com/your-username/SefraiOS.git
git branch -M main
git push -u origin main
```

### 4.2 Codemagic 빌드 트리거 설정

`codemagic.yaml` 파일이 이미 설정되어 있습니다:
- `main` 브랜치 push 시 자동 빌드
- `develop` 브랜치 push 시 자동 빌드
- Pull Request 시 자동 빌드

## 5. 첫 빌드 실행

### 5.1 Codemagic에서 수동 빌드

1. Codemagic 프로젝트 페이지
2. **Start new build** 클릭
3. Workflow: `ios-sefra-workflow`
4. Branch: `main`
5. **Start new build** 확인

### 5.2 빌드 확인 사항

빌드가 다음 단계를 거칩니다:
1. ✓ CocoaPods 설치
2. ✓ Xcode 빌드
3. ✓ Code Signing
4. ✓ IPA 파일 생성
5. ✓ TestFlight 업로드

예상 빌드 시간: **10-15분**

### 5.3 빌드 성공 시

- 이메일로 빌드 결과 통보
- IPA 파일 다운로드 가능
- TestFlight에 자동 업로드
- App Store Connect에서 베타 테스트 가능

## 6. TestFlight 베타 테스트

### 6.1 내부 테스터 추가

1. App Store Connect → **TestFlight**
2. **Internal Testing** → 빌드 선택
3. **+** 버튼 → **Add Internal Testers**
4. 테스터 이메일 추가
5. **Add** 클릭

테스터에게 초대 이메일 발송됩니다.

### 6.2 외부 테스터 추가 (선택)

1. **External Testing** → **+** 버튼
2. 그룹 이름 입력
3. 빌드 선택
4. **What to Test** 작성
5. **Submit for Review** (Apple 승인 필요)

## 7. App Store 배포

### 7.1 앱 정보 입력

App Store Connect → **App Store** 탭:

1. **App Information**
   - Subtitle
   - Category: Finance / Business
   - Age Rating

2. **Pricing and Availability**
   - Price: Free
   - Availability: All countries

3. **1.0 Prepare for Submission**
   - **Screenshots** (필수)
     - 6.7" (iPhone 15 Pro Max)
     - 6.5" (iPhone 14 Plus)
   - **App Preview** (선택)
   - **Description**
   - **Keywords**
   - **Support URL**
   - **Marketing URL** (선택)

### 7.2 제출

1. **Build** 선택
2. **Export Compliance** 설정
   - Does your app use encryption? → No (또는 Yes 및 상세 정보)
3. **Advertising Identifier** 설정
4. **Content Rights** 체크
5. **Submit for Review** 클릭

심사 시간: **평균 1-2일**

## 8. 환경 변수 체크리스트

Codemagic 빌드 전 확인:

- [ ] `APP_STORE_CONNECT_ISSUER_ID` 설정됨
- [ ] `APP_STORE_CONNECT_KEY_IDENTIFIER` 설정됨
- [ ] `APP_STORE_CONNECT_PRIVATE_KEY` 설정됨
- [ ] Code Signing (Automatic 또는 Manual) 설정됨
- [ ] Apple Developer에 `sefra.kr` App ID 생성됨
- [ ] App Store Connect에 앱 생성됨
- [ ] Git 저장소에 코드 푸시됨
- [ ] `codemagic.yaml` 파일 커밋됨

## 9. 다음 단계

### 9.1 빌드 완료 후

1. **TestFlight 확인**
   - App Store Connect → TestFlight
   - 빌드 업로드 확인
   - 내부 테스터 추가

2. **베타 테스트**
   - 테스터 피드백 수집
   - 버그 수정
   - 새 빌드 배포

3. **App Store 제출**
   - 스크린샷 준비
   - 앱 설명 작성
   - 심사 제출

### 9.2 유지보수

- **버전 업데이트**: `Info.plist`에서 `CFBundleShortVersionString` 증가
- **빌드 번호 자동 증가**: Codemagic에서 자동 처리
- **자동 배포**: `codemagic.yaml`에서 `submit_to_app_store: true` 활성화

## 10. 트러블슈팅

### "Code signing error" 발생 시

1. Apple Developer Portal에서 App ID 생성 확인
2. Bundle ID가 `sefra.kr`로 일치하는지 확인
3. Codemagic에서 Automatic Code Signing 사용 권장

### "TestFlight upload failed" 발생 시

1. App Store Connect API Key 재확인
2. Issuer ID, Key ID, Private Key 정확성 확인
3. API Key 권한이 **App Manager** 이상인지 확인

### "Build failed" 발생 시

1. Codemagic 빌드 로그 확인
2. `pod install` 오류 확인
3. Firebase 버전 확인 (10.29.0 사용 중)

## 참고 자료

- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Codemagic iOS Documentation](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/)
- [TestFlight 가이드](https://developer.apple.com/testflight/)

## 비용 안내

### Apple
- **Apple Developer Program**: $99/년 (이미 구매 완료 ✓)

### Codemagic
- **Free**: 월 500분 (시작하기 충분)
- **Professional**: $29/월 (2,000분)
- **Enterprise**: $99/월 (무제한)

### Firebase
- **Spark Plan (무료)**: 기본 기능 사용 가능
- **Blaze Plan (종량제)**: 대규모 트래픽 시
