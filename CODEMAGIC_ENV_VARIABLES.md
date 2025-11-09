# Codemagic 환경 변수 설정

## ✅ GitHub 저장소 연결 완료

- **저장소**: https://github.com/zanoone/sefra.git
- **브랜치**: `ios-app`
- **커밋**: Initial iOS app setup ✅

---

## 🔧 Codemagic 환경 변수 설정

### 1. Codemagic 프로젝트 추가

1. https://codemagic.io 로그인
2. **Add application** 클릭
3. GitHub 저장소 선택: `zanoone/sefra`
4. **Set up build** 클릭
5. Branch 선택: `ios-app`

### 2. 환경 변수 추가

**Settings** → **Environment variables**로 이동하여 다음 3개 변수를 추가하세요:

---

#### 변수 1: APP_STORE_CONNECT_ISSUER_ID

```
Key: APP_STORE_CONNECT_ISSUER_ID
Value: 832d0d84-4c28-4a4d-b5a9-ba6a9064b307
Type: Text
Secure: No
```

---

#### 변수 2: APP_STORE_CONNECT_KEY_IDENTIFIER

```
Key: APP_STORE_CONNECT_KEY_IDENTIFIER
Value: U69P2JJX7K
Type: Text
Secure: No
```

---

#### 변수 3: APP_STORE_CONNECT_PRIVATE_KEY

```
Key: APP_STORE_CONNECT_PRIVATE_KEY
Type: Text
Secure: Yes (권장)

Value: (아래 내용 전체를 복사하여 붙여넣기)
```

**Private Key 내용:**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgH3a9dLKdL3O5a/gv
2ecqC7qJSJP0DE6pP6rxB0iJZ7OgCgYIKoZIzj0DAQehRANCAARa+UKL7/2GnVYG
XE8jPf9QM0pMfMRXjMm+1PMxEeItzqSx5zt14UnLjOzsWVrP7Zdnr7CtSvs16OSx
j9F3E/Tr
-----END PRIVATE KEY-----
```

⚠️ **주의**:
- `-----BEGIN PRIVATE KEY-----` 포함하여 전체를 복사하세요
- 줄바꿈도 그대로 유지해야 합니다

---

## 🔐 Code Signing 설정

### 방법 1: Automatic Code Signing (권장)

1. **Settings** → **Code signing identities** → **iOS code signing**
2. **Enable automatic code signing** 체크
3. Apple ID 입력
4. App-specific password 생성:
   - https://appleid.apple.com/
   - **Sign-in and Security** → **App-specific passwords**
   - **Generate password...**
   - 생성된 비밀번호 복사하여 Codemagic에 입력

### 방법 2: Manual Code Signing

인증서를 직접 업로드하려면 **APPLE_DEVELOPER_SETUP.md** 참고

---

## 📋 codemagic.yaml 설정 확인

프로젝트에 이미 `codemagic.yaml` 파일이 있습니다:

```yaml
workflows:
  ios-sefra-workflow:
    name: iOS Sefra Build
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: sefra.kr
```

**빌드 트리거:**
- `ios-app` 브랜치에 push 시 자동 빌드
- Pull Request 생성 시 자동 빌드

---

## 🚀 첫 번째 빌드 실행

### 1. Codemagic에서 수동 빌드

1. Codemagic 프로젝트 페이지
2. **Start new build** 클릭
3. Workflow: `ios-sefra-workflow`
4. Branch: `ios-app`
5. **Start new build** 클릭

### 2. 빌드 진행 확인

빌드가 다음 단계를 거칩니다:
```
1. ✓ Repository clone
2. ✓ CocoaPods install
3. ✓ Xcode build
4. ✓ Code signing
5. ✓ IPA creation
6. ✓ TestFlight upload
```

**예상 시간**: 10-15분

### 3. 빌드 성공 시

- 이메일로 빌드 결과 통보
- IPA 파일 다운로드 가능
- TestFlight에 자동 업로드
- App Store Connect에서 확인 가능

---

## ✅ 환경 변수 체크리스트

빌드 전 모든 항목이 설정되었는지 확인:

- [ ] `APP_STORE_CONNECT_ISSUER_ID` = `832d0d84-4c28-4a4d-b5a9-ba6a9064b307`
- [ ] `APP_STORE_CONNECT_KEY_IDENTIFIER` = `U69P2JJX7K`
- [ ] `APP_STORE_CONNECT_PRIVATE_KEY` = (Private Key 전체 내용)
- [ ] Code Signing 설정 (Automatic 또는 Manual)
- [ ] GitHub 저장소 연결: `zanoone/sefra`
- [ ] Branch 설정: `ios-app`

---

## 🔍 트러블슈팅

### "Code signing error"

**원인**: 인증서 또는 프로비저닝 프로파일 문제

**해결**:
1. Automatic Code Signing 사용 권장
2. Apple Developer Portal에서 App ID (`sefra.kr`) 생성 확인
3. Bundle ID가 일치하는지 확인

### "Invalid API Key"

**원인**: App Store Connect API Key가 잘못됨

**해결**:
1. Issuer ID, Key ID 재확인
2. Private Key가 전체 복사되었는지 확인 (-----BEGIN PRIVATE KEY----- 포함)
3. 줄바꿈이 유지되었는지 확인

### "TestFlight upload failed"

**원인**: API Key 권한 문제

**해결**:
1. App Store Connect에서 API Key 권한 확인
2. **App Manager** 이상의 권한 필요
3. App Store Connect에 앱이 생성되었는지 확인

---

## 📞 다음 단계

### 1. Codemagic 빌드 성공 후

1. **TestFlight 확인**
   - App Store Connect → TestFlight
   - 빌드 업로드 확인

2. **내부 테스터 추가**
   - Internal Testing → Add Testers
   - 이메일 추가

3. **베타 테스트**
   - TestFlight 앱으로 다운로드
   - 기능 테스트

### 2. App Store 배포 준비

1. **스크린샷 준비**
   - 6.7" (iPhone 15 Pro Max)
   - 6.5" (iPhone 14 Plus)

2. **앱 설명 작성**
   - Description
   - Keywords
   - Support URL

3. **제출**
   - Submit for Review
   - 심사 대기 (1-2일)

---

## 📚 관련 문서

- [APPLE_DEVELOPER_SETUP.md](APPLE_DEVELOPER_SETUP.md) - Apple Developer 상세 설정
- [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md) - Codemagic 전체 가이드
- [README.md](README.md) - 프로젝트 개요
- [FINAL_SUMMARY.md](../FINAL_SUMMARY.md) - 완료 요약

---

**마지막 업데이트**: 2025-11-09
**GitHub 브랜치**: ios-app
**빌드 상태**: 환경 변수 설정 대기 중
