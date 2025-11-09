# 한글 푸시 알림 테스트 가이드

## 🚨 중요: iOS 시뮬레이터는 푸시 알림을 받을 수 없습니다!
- 실제 아이폰 디바이스가 필요합니다
- TestFlight 또는 Xcode로 직접 설치

## 📋 사전 준비

### 1. Firebase Service Account Key 다운로드
```bash
# Firebase Console에서 다운로드:
# https://console.firebase.google.com/project/sefra-5f70b/settings/serviceaccounts/adminsdk

# 다운로드한 파일을 다음 위치에 저장:
/Users/admin/SefraiOS/service-account-key.json
```

**단계:**
1. Firebase Console 접속: https://console.firebase.google.com/project/sefra-5f70b
2. Settings (⚙️) > Service Accounts
3. "Generate New Private Key" 클릭
4. 다운로드한 JSON 파일을 `service-account-key.json`로 저장

### 2. FCM 토큰 가져오기

**실제 디바이스에서:**
1. TestFlight 또는 Xcode로 앱 설치
2. 앱 실행
3. Xcode Console에서 FCM 토큰 확인:
   ```
   🆕 새 FCM 토큰: fXyZ789def...
   ```

**또는 서버 DB에서:**
```sql
SELECT fcm_token FROM devices WHERE user_id = 'YOUR_USER_ID';
```

## 🚀 사용법

### 기본 사용 (한글 메시지)
```bash
cd /Users/admin/SefraiOS
node firebase-messaging.js YOUR_FCM_TOKEN_HERE
```

### 예시
```bash
node firebase-messaging.js fXyZ789defGHI456jklMNO123pqrSTU789vwxYZ012
```

## 📨 테스트 메시지

스크립트는 다음 한글 메시지를 전송합니다:

**메시지 1:**
- 제목: 안녕하세요! 👋
- 본문: SefraiOS 푸시 알림 테스트입니다.

**메시지 2:**
- 제목: 새로운 메시지가 도착했습니다 📨
- 본문: 한글 푸시 알림이 정상적으로 작동하고 있습니다.

**메시지 3:**
- 제목: 테스트 알림
- 본문: 이것은 한글과 English가 섞인 mixed 메시지입니다.

## ✅ 성공 시 출력

```
✅ Firebase Admin initialized successfully

🔔 Sending push notification with Korean text...
📱 Target token: fXyZ789def...

✅ Push notification sent successfully!
📬 Message ID: projects/sefra-5f70b/messages/...

📋 Message details:
   Title: 안녕하세요! 👋
   Body: SefraiOS 푸시 알림 테스트입니다.
   Data: {
     "type": "test",
     "timestamp": "2025-11-10T..."
   }

🎉 Check your device for the notification!
```

## ❌ 일반적인 오류

### 1. `registration-token-not-registered`
**원인:**
- 토큰이 삭제됨 (빌드 41-42의 토큰 리셋 때문)
- 앱 재설치로 토큰 변경됨
- 토큰이 서버에 전송 안 됨

**해결:**
1. 새로운 FCM 토큰 가져오기 (Xcode Console 확인)
2. 서버 DB에서 최신 토큰 확인
3. 빌드 42의 토큰 전송 로직 확인

### 2. `service-account-key.json not found`
**해결:**
Firebase Console에서 Service Account Key 다운로드

### 3. `No FCM token provided`
**해결:**
스크립트 실행 시 FCM 토큰을 인자로 전달

## 🔍 디버깅

### 앱 로그 확인 (실제 디바이스)
```bash
# Xcode에서
# Window > Devices and Simulators
# 디바이스 선택 > View Device Logs
```

### 서버에서 토큰 전송 확인
```bash
# 서버 로그에서 다음 확인:
✅ iOS 디바이스 토큰 저장 완료
   토큰: fXyZ789def...
```

## 📞 관련 문서

- Firebase Console: https://console.firebase.google.com/project/sefra-5f70b
- Cloud Messaging: https://console.firebase.google.com/project/sefra-5f70b/settings/cloudmessaging
- 트러블슈팅 로그: /Users/admin/SefraiOS/1110.md
