# 빠른 시작 가이드

iOS 앱을 최대한 빠르게 실행하는 방법입니다.

## 필수 준비사항

- macOS 13.0+
- Xcode 15.0+
- CocoaPods
- Firebase 프로젝트

## 5분 안에 시작하기

### 1. Firebase 설정 (1분)

```bash
# Firebase Console에서 GoogleService-Info.plist 다운로드
# https://console.firebase.google.com/

# 다운로드한 파일을 프로젝트에 복사
cp ~/Downloads/GoogleService-Info.plist SefraiOS/SefraiOS/
```

### 2. 의존성 설치 (2분)

```bash
cd SefraiOS
pod install
```

### 3. Xcode에서 열기 (10초)

```bash
open SefraiOS.xcworkspace
```

⚠️ **중요**: `.xcworkspace` 파일을 열어야 합니다! (`.xcodeproj` 아님)

### 4. 시뮬레이터 실행 (1분)

1. Xcode 상단에서 시뮬레이터 선택 (예: iPhone 15 Pro)
2. `Cmd + R` 누르기
3. 완료!

## 자동 빌드 스크립트 사용

```bash
cd SefraiOS
./build.sh
```

## 주요 기능 테스트

### WebView 테스트
- 앱 실행 시 자동으로 https://sefra.kr 로드됨

### Face ID 테스트 (시뮬레이터)
1. 앱에서 생체인증 요청
2. 시뮬레이터 메뉴: Features → Face ID → Enrolled
3. 인증 프롬프트에서: Features → Face ID → Matching Face

### 웹 디버깅
1. Safari 열기
2. 개발자 → Simulator → SefraiOS
3. 웹 인스펙터에서 콘솔 확인

## 다음 단계

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - 전체 설정 가이드
- [README.md](README.md) - 프로젝트 문서
- Codemagic 설정하여 자동 빌드
- TestFlight 또는 App Store 배포

## 문제 해결

### "CocoaPods not found"
```bash
sudo gem install cocoapods
```

### "GoogleService-Info.plist not found"
Firebase Console에서 다운로드하여 `SefraiOS/SefraiOS/` 폴더에 추가

### 서명 오류
Xcode → Signing & Capabilities → Team 선택

### 더 많은 도움이 필요하신가요?
[SETUP_GUIDE.md](SETUP_GUIDE.md)의 트러블슈팅 섹션을 확인하세요.
