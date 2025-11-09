# Codemagic 환경 설정 가이드

Codemagic에서 iOS 앱을 빌드하고 배포하기 위한 완전한 설정 가이드입니다.

## 1. Codemagic 계정 생성 및 프로젝트 연결

### 1.1 Codemagic 가입
1. https://codemagic.io 접속
2. "Start building for free" 클릭
3. GitHub/GitLab/Bitbucket 계정으로 로그인

### 1.2 프로젝트 추가
1. "Add application" 클릭
2. Git 저장소 선택
3. `SefraiOS` 프로젝트 선택
4. "Set up build" 클릭

## 2. 필수 환경 변수 설정

Codemagic 프로젝트 → **Settings** → **Environment variables**로 이동

### 2.1 App Store Connect API Key

#### Step 1: App Store Connect에서 API Key 생성

1. https://appstoreconnect.apple.com/ 로그인
2. **Users and Access** → **Keys** 탭
3. **+** 버튼 클릭 → **Generate API Key**
4. 설정:
   - **Name**: `Codemagic CI/CD`
   - **Access**: Developer 또는 App Manager
5. **Generate** 클릭
6. `.p8` 파일 다운로드 (⚠️ 한 번만 다운로드 가능!)
7. 다음 정보 기록:
   - **Issuer ID** (페이지 상단)
   - **Key ID** (생성된 키 옆)

#### Step 2: Codemagic에 환경 변수 추가

| 변수 이름 | 값 | 설명 |
|----------|---|------|
| `APP_STORE_CONNECT_ISSUER_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | `XXXXXXXXXX` | API Key ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | `.p8` 파일 내용 전체 | API Private Key (줄바꿈 포함) |

**APP_STORE_CONNECT_PRIVATE_KEY 설정 방법:**
```bash
# .p8 파일 내용을 복사
cat AuthKey_XXXXXXXXXX.p8

# 출력된 내용 전체를 복사 (-----BEGIN PRIVATE KEY----- 부터 -----END PRIVATE KEY----- 까지)
# Codemagic 환경 변수에 붙여넣기
```

### 2.2 iOS Code Signing (서명 인증서)

#### 방법 1: Automatic Code Signing (권장)

Codemagic가 자동으로 인증서를 생성하고 관리합니다.

1. Codemagic → **Settings** → **Code signing identities**
2. **iOS code signing** 섹션
3. **Automatic code signing** 선택
4. Apple Developer Portal 자격증명 입력:
   - Apple ID
   - App-specific password (2FA 사용 시)

#### 방법 2: Manual Code Signing

직접 인증서를 생성하여 업로드합니다.

**필요한 파일:**
- Distribution Certificate (`.p12`)
- Provisioning Profile (`.mobileprovision`)

**인증서 생성 방법:**

```bash
# 1. Certificate Signing Request (CSR) 생성
# Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
# 이메일 입력, "Saved to disk" 선택

# 2. Apple Developer Portal에서 Distribution Certificate 생성
# Certificates, Identifiers & Profiles → Certificates → + 버튼
# Apple Distribution 선택 → CSR 업로드

# 3. 인증서 다운로드 및 .p12로 변환
# 다운로드한 인증서를 Keychain에 추가
# Keychain에서 인증서 선택 → 우클릭 → Export
# 비밀번호 설정 (CERTIFICATE_PRIVATE_KEY에 사용)

# 4. Provisioning Profile 생성
# Profiles → + 버튼 → App Store Distribution
# App ID: sefra.kr 선택
# Distribution Certificate 선택
# Profile 이름 입력 → Generate → 다운로드
```

**Codemagic에 업로드:**
1. Code signing identities → **Upload certificate**
2. `.p12` 파일 업로드
3. 비밀번호 입력
4. **Upload profile** 클릭
5. `.mobileprovision` 파일 업로드

**환경 변수 추가:**
| 변수 이름 | 값 |
|----------|---|
| `CERTIFICATE_PRIVATE_KEY` | `.p12` 파일 비밀번호 |

### 2.3 기타 환경 변수 (선택사항)

| 변수 이름 | 값 | 설명 |
|----------|---|------|
| `BUNDLE_ID` | `sefra.kr` | iOS 번들 ID |
| `XCODE_WORKSPACE` | `SefraiOS.xcworkspace` | Xcode Workspace 이름 |
| `XCODE_SCHEME` | `SefraiOS` | Xcode Scheme 이름 |

## 3. codemagic.yaml 설정

프로젝트에 이미 `codemagic.yaml` 파일이 포함되어 있습니다.

### 3.1 현재 설정 확인

```yaml
workflows:
  ios-sefra-workflow:
    name: iOS Sefra Build
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: sefra.kr  # ✅ 번들 ID 확인
```

### 3.2 빌드 트리거 설정

현재 설정된 트리거:
- `main` 브랜치에 push
- `develop` 브랜치에 push
- Pull Request 생성

변경이 필요하면 `codemagic.yaml` 수정:
```yaml
triggering:
  events:
    - push
    - tag
  branch_patterns:
    - pattern: 'main'
      include: true
```

### 3.3 빌드 이메일 설정

`codemagic.yaml`에서 이메일 수신자 변경:
```yaml
publishing:
  email:
    recipients:
      - your-email@example.com  # ← 여기를 본인 이메일로 변경
```

## 4. Firebase 설정 (GoogleService-Info.plist)

### 4.1 Firebase Console에서 iOS 앱 추가

1. https://console.firebase.google.com/ 접속
2. 프로젝트 선택 (Android와 동일한 프로젝트)
3. **프로젝트 설정** → **일반** → **내 앱**
4. **앱 추가** → **iOS** 선택
5. 정보 입력:
   - **Apple 번들 ID**: `sefra.kr`
   - **앱 닉네임**: Sefra iOS
6. **앱 등록** 클릭
7. `GoogleService-Info.plist` 다운로드

### 4.2 프로젝트에 파일 추가

```bash
# 다운로드한 파일을 프로젝트에 복사
cp ~/Downloads/GoogleService-Info.plist SefraiOS/SefraiOS/
```

### 4.3 Git에 커밋

```bash
cd SefraiOS
git add SefraiOS/GoogleService-Info.plist
git commit -m "Add GoogleService-Info.plist"
git push
```

**⚠️ 보안 참고:**
- `GoogleService-Info.plist`는 공개 저장소에 커밋해도 안전합니다 (API Key가 아닌 설정 파일)
- 민감한 정보는 Codemagic 환경 변수에만 저장

## 5. 빌드 워크플로우 실행

### 5.1 수동 빌드 실행

1. Codemagic 프로젝트 페이지
2. **Start new build** 클릭
3. Workflow 선택: `ios-sefra-workflow`
4. Branch 선택: `main`
5. **Start new build** 확인

### 5.2 자동 빌드 트리거

```bash
# main 브랜치에 push
git push origin main

# Codemagic가 자동으로 빌드 시작
```

### 5.3 빌드 모니터링

1. Codemagic에서 빌드 진행 상황 확인
2. 로그 확인:
   - CocoaPods 설치
   - Xcode 빌드
   - Code Signing
   - IPA 생성
3. 예상 빌드 시간: 10-15분

## 6. TestFlight 자동 배포

### 6.1 App Store Connect에서 앱 생성

1. https://appstoreconnect.apple.com/ 로그인
2. **My Apps** → **+** → **New App**
3. 정보 입력:
   - **Platform**: iOS
   - **Name**: Sefra
   - **Primary Language**: Korean
   - **Bundle ID**: sefra.kr
   - **SKU**: sefra-ios-app
   - **User Access**: Full Access

### 6.2 codemagic.yaml 확인

TestFlight 자동 업로드 설정이 이미 되어 있습니다:
```yaml
publishing:
  app_store_connect:
    api_key: $APP_STORE_CONNECT_PRIVATE_KEY
    key_id: $APP_STORE_CONNECT_KEY_IDENTIFIER
    issuer_id: $APP_STORE_CONNECT_ISSUER_ID
    submit_to_testflight: true  # ✅ TestFlight 자동 업로드
```

### 6.3 빌드 완료 후

1. 빌드 성공 시 자동으로 TestFlight에 업로드
2. App Store Connect → TestFlight에서 확인
3. 내부/외부 테스터 추가
4. 테스터에게 초대 이메일 발송

## 7. 환경 변수 체크리스트

빌드 전 다음 환경 변수가 모두 설정되었는지 확인:

- [ ] `APP_STORE_CONNECT_ISSUER_ID`
- [ ] `APP_STORE_CONNECT_KEY_IDENTIFIER`
- [ ] `APP_STORE_CONNECT_PRIVATE_KEY`
- [ ] iOS Code Signing (Automatic 또는 Manual)
- [ ] `CERTIFICATE_PRIVATE_KEY` (Manual Code Signing 사용 시)

## 8. 트러블슈팅

### 빌드 실패: "Code signing error"

**원인**: 인증서 또는 프로비저닝 프로파일 문제

**해결:**
1. Bundle ID가 일치하는지 확인: `sefra.kr`
2. Apple Developer Portal에서 App ID 생성 확인
3. Provisioning Profile이 유효한지 확인
4. Codemagic에서 Automatic Code Signing 사용 권장

### 빌드 실패: "Pod install failed"

**원인**: CocoaPods 의존성 문제

**해결:**
1. `Podfile.lock` 삭제 후 재커밋
2. `Podfile`의 플랫폼 버전 확인: `platform :ios, '14.0'`

### 빌드 실패: "GoogleService-Info.plist not found"

**원인**: Firebase 설정 파일 누락

**해결:**
1. Firebase Console에서 파일 다운로드
2. `SefraiOS/SefraiOS/GoogleService-Info.plist`에 추가
3. Git에 커밋 및 푸시

### TestFlight 업로드 실패

**원인**: App Store Connect API Key 문제

**해결:**
1. Issuer ID, Key ID, Private Key 재확인
2. API Key의 권한 확인 (Developer 또는 App Manager)
3. App Store Connect에서 앱이 생성되었는지 확인

## 9. 비용 및 제한사항

### Codemagic 무료 플랜
- **빌드 시간**: 월 500분
- **동시 빌드**: 1개
- **팀 크기**: 3명

### Codemagic 유료 플랜
- **Professional**: $29/월 (2,000분)
- **Enterprise**: $99/월 (무제한)

### Apple Developer Program
- **연간 비용**: $99 (필수)
- TestFlight 및 App Store 배포 포함

## 10. 다음 단계

빌드 및 배포가 성공하면:

1. **TestFlight 테스트**
   - 내부 테스터 추가
   - 베타 테스트 진행

2. **App Store 제출**
   - 스크린샷 준비
   - 앱 설명 작성
   - 제출 및 심사 대기

3. **CI/CD 자동화**
   - 자동 버전 번호 증가
   - 자동 배포 파이프라인 최적화

## 참고 자료

- [Codemagic iOS Documentation](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
