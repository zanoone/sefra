# iOS 앱 설정 가이드

이 문서는 Sefra iOS 앱을 처음부터 설정하는 방법을 단계별로 설명합니다.

## 1. Mac 환경 설정

### 필수 소프트웨어 설치

```bash
# Xcode 설치 (App Store에서)
# Command Line Tools 설치
xcode-select --install

# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# CocoaPods 설치
sudo gem install cocoapods
```

## 2. Firebase 프로젝트 설정

### 2.1 Firebase Console에서 iOS 앱 추가

1. https://console.firebase.google.com/ 접속
2. 기존 Android 프로젝트 선택 (또는 새 프로젝트 생성)
3. 프로젝트 설정 → 일반 → "내 앱" 섹션
4. "앱 추가" → iOS 선택
5. 다음 정보 입력:
   - **Apple 번들 ID**: `com.sefra` (또는 원하는 고유 ID)
   - **앱 닉네임**: `Sefra iOS`
   - **App Store ID**: (선택사항, 나중에 추가 가능)

### 2.2 GoogleService-Info.plist 다운로드

1. Firebase Console에서 `GoogleService-Info.plist` 다운로드
2. 파일을 다음 위치에 복사:
   ```
   SefraiOS/SefraiOS/GoogleService-Info.plist
   ```

### 2.3 Cloud Messaging 설정

1. Firebase Console → 프로젝트 설정 → Cloud Messaging
2. iOS 앱 구성 → APNs 인증 키 업로드
   - Apple Developer Console에서 APNs 키 생성
   - 키 ID, 팀 ID 입력

## 3. Apple Developer 계정 설정

### 3.1 Apple Developer Program 등록

- https://developer.apple.com/ 에서 계정 등록
- 연간 $99 비용 (개인/조직)

### 3.2 App ID 생성

1. Apple Developer Console → Certificates, Identifiers & Profiles
2. Identifiers → "+" 버튼
3. App IDs 선택
4. 설정:
   - **Description**: Sefra iOS
   - **Bundle ID**: `com.sefra` (Explicit)
   - **Capabilities**:
     - Push Notifications 체크
     - Associated Domains (선택사항)

### 3.3 APNs 인증 키 생성

1. Keys → "+" 버튼
2. Key Name 입력: `Sefra APNs Key`
3. Apple Push Notifications service (APNs) 체크
4. Continue → Register
5. `.p8` 파일 다운로드 (한 번만 가능!)
6. Key ID 기록

### 3.4 프로비저닝 프로파일 생성

#### Development Profile
1. Profiles → "+" 버튼
2. iOS App Development 선택
3. App ID 선택: `com.sefra`
4. 인증서 선택
5. 디바이스 선택
6. 프로파일 이름: `Sefra Development`
7. 다운로드

#### Distribution Profile (App Store)
1. Profiles → "+" 버튼
2. App Store 선택
3. App ID 선택: `com.sefra`
4. Distribution 인증서 선택
5. 프로파일 이름: `Sefra Distribution`
6. 다운로드

## 4. Xcode 프로젝트 설정

### 4.1 프로젝트 열기

```bash
cd SefraiOS
pod install
open SefraiOS.xcworkspace
```

### 4.2 서명 설정

1. Xcode에서 프로젝트 선택
2. TARGETS → SefraiOS → Signing & Capabilities
3. **Automatically manage signing** 체크 (추천)
   - Team 선택
   - Bundle Identifier 확인: `com.sefra`
4. 또는 수동 서명:
   - Automatically manage signing 체크 해제
   - Provisioning Profile 수동 선택

### 4.3 Capabilities 추가

1. Signing & Capabilities 탭
2. "+ Capability" 버튼 클릭
3. 다음 추가:
   - **Push Notifications**
   - **Background Modes**
     - Remote notifications 체크

## 5. 시뮬레이터 테스트

### 5.1 시뮬레이터 실행

1. Xcode에서 시뮬레이터 선택 (예: iPhone 15 Pro)
2. `Cmd + R` 또는 Run 버튼 클릭
3. 앱이 시뮬레이터에서 실행됨

### 5.2 Face ID 시뮬레이션

시뮬레이터에서 Face ID 테스트:
1. 시뮬레이터 실행 중
2. Features → Face ID → Enrolled
3. 생체인증 프롬프트에서:
   - Features → Face ID → Matching Face (성공)
   - Features → Face ID → Non-matching Face (실패)

### 5.3 웹뷰 디버깅

1. Safari 열기 (Mac)
2. 환경설정 → 고급 → "메뉴 막대에서 개발자용 메뉴 보기" 체크
3. 개발자 → Simulator → SefraiOS
4. 웹 인스펙터 열림

## 6. 실제 디바이스 테스트

### 6.1 디바이스 등록

1. Apple Developer Console → Devices
2. "+" 버튼
3. Device Name, UDID 입력
   - UDID는 Xcode → Window → Devices and Simulators에서 확인

### 6.2 디바이스에서 실행

1. iPhone을 Mac에 USB 연결
2. Xcode에서 디바이스 선택
3. "Trust This Computer" 허용
4. `Cmd + R` 실행
5. iPhone에서 "설정 → 일반 → VPN 및 기기 관리 → 개발자 앱 신뢰" 선택

## 7. Codemagic 설정

### 7.1 Codemagic 계정 생성

1. https://codemagic.io/ 접속
2. GitHub/GitLab/Bitbucket 연동
3. 프로젝트 추가

### 7.2 환경 변수 설정

Codemagic 프로젝트 설정 → Environment variables:

```
APP_STORE_CONNECT_ISSUER_ID = [App Store Connect Issuer ID]
APP_STORE_CONNECT_KEY_IDENTIFIER = [API Key ID]
APP_STORE_CONNECT_PRIVATE_KEY = [API Key 내용]
CERTIFICATE_PRIVATE_KEY = [P12 인증서 비밀번호]
```

### 7.3 App Store Connect API Key 생성

1. App Store Connect 로그인
2. Users and Access → Keys
3. "+" 버튼 → Create New Key
4. Name: `Codemagic CI`
5. Access: Developer 또는 App Manager
6. Generate → `.p8` 파일 다운로드
7. Issuer ID, Key ID 기록

### 7.4 서명 인증서 업로드

1. Codemagic → Code signing identities
2. iOS certificates 추가
3. Distribution certificate (.p12 파일) 업로드
4. Provisioning profiles 추가

### 7.5 빌드 워크플로우 설정

`codemagic.yaml` 파일이 이미 프로젝트에 포함되어 있습니다.

빌드 트리거:
- `main` 브랜치에 push
- Pull request 생성

## 8. TestFlight 배포

### 8.1 App Store Connect 앱 생성

1. App Store Connect 로그인
2. My Apps → "+" → New App
3. 정보 입력:
   - **Platform**: iOS
   - **Name**: Sefra
   - **Primary Language**: Korean
   - **Bundle ID**: com.sefra
   - **SKU**: com.sefra.ios

### 8.2 Codemagic 빌드 실행

1. 코드를 `main` 브랜치에 push
2. Codemagic에서 자동으로 빌드 시작
3. 빌드 완료 후 TestFlight에 자동 업로드
4. App Store Connect → TestFlight에서 확인

### 8.3 내부 테스터 추가

1. App Store Connect → TestFlight
2. Internal Testing → Add Testers
3. 테스터 이메일 추가
4. 테스터에게 초대 이메일 발송

## 9. App Store 배포

### 9.1 앱 정보 입력

App Store Connect → App Information:
- App Name
- Subtitle
- Category
- Age Rating

### 9.2 스크린샷 및 앱 설명

1. App Store → 1.0 Prepare for Submission
2. 스크린샷 업로드 (필수):
   - 6.5" (iPhone 15 Pro Max)
   - 5.5" (iPhone 8 Plus)
3. 앱 설명 작성
4. 키워드, 지원 URL, 마케팅 URL

### 9.3 제출

1. Build 선택
2. Export Compliance 정보 입력
3. Submit for Review
4. 승인 대기 (보통 1-2일)

## 10. 트러블슈팅

### CocoaPods 오류

```bash
# 캐시 정리
pod cache clean --all
pod deintegrate
rm Podfile.lock
pod install
```

### 서명 오류

- Bundle Identifier가 일치하는지 확인
- Provisioning Profile이 만료되지 않았는지 확인
- 인증서가 유효한지 확인

### Firebase 연결 오류

- `GoogleService-Info.plist` 파일 위치 확인
- Bundle Identifier가 Firebase Console과 일치하는지 확인

### 생체인증 실패

- Info.plist에 `NSFaceIDUsageDescription` 추가 확인
- 시뮬레이터에서 Face ID Enrolled 상태 확인

## 참고 자료

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Codemagic Documentation](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/)
- [CocoaPods Guides](https://guides.cocoapods.org/)
