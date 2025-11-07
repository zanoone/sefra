# Apple Developer Portal 설정 가이드

## 1. Bundle ID 등록

### 단계 1: Identifiers 생성
1. https://developer.apple.com/account 접속
2. **Certificates, Identifiers & Profiles** 선택
3. 왼쪽 메뉴에서 **Identifiers** 클릭
4. 오른쪽 상단 ➕ 버튼 클릭
5. **App IDs** 선택 → Continue

### 단계 2: Bundle ID 입력
- **Description**: Sefra iOS App
- **Bundle ID**: **Explicit** 선택
- **Bundle ID 입력**: `sefra.kr`

### 단계 3: Capabilities 선택
아래 항목들을 체크하세요:
- ✅ **Push Notifications** (FCM용)
- ✅ **Associated Domains** (Universal Links용)
- ✅ **Sign in with Apple** (선택사항)

### 단계 4: 등록
- Continue → Register 클릭

---

## 2. App Store Connect API Key 생성

Codemagic에서 자동 빌드를 위해 필요합니다.

### 단계 1: API Key 생성
1. https://appstoreconnect.apple.com 접속
2. 상단 **Users and Access** 클릭
3. **Keys** 탭 선택
4. ➕ 버튼 클릭 (또는 "Generate API Key")

### 단계 2: Key 정보 입력
- **Name**: Codemagic CI
- **Access**: **Admin** 또는 **App Manager** 선택
- Generate 클릭

### 단계 3: Key 정보 저장
생성 후 다음 정보를 복사하세요 (한 번만 표시됩니다!):
- **Key ID**: 예) ABC1234567
- **Issuer ID**: 예) 12345678-1234-1234-1234-123456789012
- **Download API Key**: `.p8` 파일 다운로드

⚠️ **중요**: .p8 파일은 한 번만 다운로드 가능하므로 안전하게 보관하세요!

---

## 3. Codemagic 환경 변수 설정

### Codemagic 대시보드 설정
1. https://codemagic.io 접속
2. Sefra_main 프로젝트 선택
3. **Settings** (⚙️) → **Environment variables** 클릭

### 환경 변수 추가

#### APP_STORE_CONNECT_KEY_IDENTIFIER
- **Variable name**: `APP_STORE_CONNECT_KEY_IDENTIFIER`
- **Variable value**: Key ID (예: ABC1234567)
- ✅ Secure 체크

#### APP_STORE_CONNECT_ISSUER_ID
- **Variable name**: `APP_STORE_CONNECT_ISSUER_ID`
- **Variable value**: Issuer ID (예: 12345678-1234-1234-1234-123456789012)
- ✅ Secure 체크

#### APP_STORE_CONNECT_API_KEY
- **Variable name**: `APP_STORE_CONNECT_API_KEY`
- **Variable value**: .p8 파일의 전체 내용을 복사 붙여넣기
  ```
  -----BEGIN PRIVATE KEY-----
  MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
  ...전체 키 내용...
  -----END PRIVATE KEY-----
  ```
- ✅ Secure 체크

---

## 4. 빌드 실행

### Codemagic에서 빌드
1. Codemagic 대시보드에서 **Start new build** 클릭
2. **Workflow** 선택:
   - **ios-release**: App Store 배포용
   - **ios-debug**: 개발/테스트용
3. **Start new build** 클릭

### 첫 번째 빌드 시 자동 생성되는 것들
Codemagic가 자동으로:
- ✅ Development Certificate 생성
- ✅ Distribution Certificate 생성
- ✅ Development Provisioning Profile 생성
- ✅ App Store Provisioning Profile 생성

---

## 5. Firebase APNs 설정

### APNs 인증 키 생성
1. https://developer.apple.com/account 접속
2. **Certificates, Identifiers & Profiles** 선택
3. 왼쪽 메뉴에서 **Keys** 클릭
4. ➕ 버튼 클릭
5. **Key Name**: Firebase APNs Key
6. ✅ **Apple Push Notifications service (APNs)** 체크
7. Continue → Register
8. **.p8 파일 다운로드** (Key ID 기억)

### Firebase Console에 업로드
1. https://console.firebase.google.com 접속
2. Sefra 프로젝트 선택
3. **프로젝트 설정** (⚙️) → **Cloud Messaging** 탭
4. **Apple 앱 구성** 섹션에서:
   - **APNs 인증 키 업로드** 클릭
   - .p8 파일 선택
   - **Key ID** 입력
   - **Team ID** 입력 (Apple Developer Portal에서 확인)
5. 업로드 클릭

---

## 6. 문제 해결

### "No matching profiles found" 오류
**원인**: Bundle ID가 Apple Developer Portal에 등록되지 않음

**해결**:
1. 위의 "1. Bundle ID 등록" 단계를 먼저 완료하세요
2. App Store Connect API Key가 올바르게 설정되었는지 확인
3. Codemagic에서 **ios-release** 워크플로우를 실행하세요 (development 대신)

### API Key 오류
**원인**: Codemagic 환경 변수가 잘못 설정됨

**해결**:
1. .p8 파일 전체 내용이 올바르게 복사되었는지 확인
2. Key ID와 Issuer ID가 정확한지 확인
3. API Key에 Admin 또는 App Manager 권한이 있는지 확인

### Signing 오류
**원인**: Certificate 또는 Provisioning Profile 문제

**해결**:
1. Codemagic에서 빌드 로그 확인
2. Apple Developer Portal에서 Certificates와 Profiles 삭제 후 재생성
3. Codemagic에서 "Reset iOS credentials" 실행

---

## 7. 체크리스트

빌드 전 확인 사항:

- [ ] Apple Developer 계정 활성화됨
- [ ] Bundle ID `sefra.kr` 등록됨
- [ ] Push Notifications, Associated Domains 활성화됨
- [ ] App Store Connect API Key 생성됨
- [ ] Codemagic 환경 변수 3개 설정됨
- [ ] Firebase APNs 키 업로드됨
- [ ] GoogleService-Info.plist 파일이 프로젝트에 포함됨

---

## 8. 참고 자료

- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Codemagic Documentation](https://docs.codemagic.io/yaml-signing-ios/signing-ios/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [APNs 설정 가이드](https://firebase.google.com/docs/cloud-messaging/ios/certs)

---

## 📧 문의

문제가 계속되면 빌드 로그와 함께 문의하세요.
- Codemagic 빌드 로그
- Apple Developer Portal 스크린샷
- Firebase Console 설정 확인
