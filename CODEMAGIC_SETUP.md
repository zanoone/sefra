# Codemagic 설정 가이드

## 🔧 Firebase 빌드 에러 해결 완료

**문제:**
```
Include of non-modular header inside framework module 'firebase_messaging'
```

**해결:**
- ✅ Podfile을 static linkage로 변경
- ✅ Pod 클린 설치 스크립트 추가
- ✅ Firebase 설정 자동화

---

## 📱 iOS만 빌드하는 방법

### 현재 상태:
- `codemagic.yaml`에는 **iOS만** 설정되어 있음
- Android가 빌드되는 이유: Codemagic UI에서 설정된 것일 수 있음

### 해결 방법:

#### 1️⃣ Codemagic UI에서 설정 확인

1. **Codemagic 대시보드 접속**: https://codemagic.io/apps
2. **Sefra 프로젝트 클릭**
3. **Workflow settings** 클릭
4. **Build** 섹션에서:
   - ✅ **iOS** 체크
   - ❌ **Android** 체크 해제
5. **Save** 클릭

#### 2️⃣ 또는 workflow만 선택

빌드 시작 시:
1. **Start new build** 클릭
2. **Workflow** 드롭다운에서 **"ios-workflow"** 선택
3. **Start new build** 클릭

---

## 🔐 환경 변수 설정 (필수)

Firebase가 작동하려면 **환경 변수**를 Codemagic에 추가해야 합니다.

### Codemagic UI에서 환경 변수 추가:

1. **Codemagic 대시보드** → **Sefra 프로젝트**
2. **Settings** (톱니바퀴 아이콘) 클릭
3. **Environment variables** 섹션
4. **Add variable** 클릭

**추가할 환경 변수:**

| Variable name | Value | Secure |
|--------------|-------|--------|
| `GOOGLE_SERVICE_INFO_PLIST` | 아래 base64 값 | ✅ Check |

**Value (전체 복사):**
```
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0IFBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo8ZGljdD4KCTxrZXk+QVBJX0tFWTwva2V5PgoJPHN0cmluZz5BSXphU3lBa2RiX2g4dnVBM1Q2TVRCbkFGTGp5WEI2R0pZMmdKa2s8L3N0cmluZz4KCTxrZXk+R0NNX1NFTkRFUl9JRDwva2V5PgoJPHN0cmluZz40OTA5MDY4ODI1ODE8L3N0cmluZz4KCTxrZXk+UExJU1RfVkVSU0lPTjwva2V5PgoJPHN0cmluZz4xPC9zdHJpbmc+Cgk8a2V5PkJVTkRMRV9JRDwva2V5PgoJPHN0cmluZz5jb20uc2VmcmEuc2VmcmFGbHV0dGVyPC9zdHJpbmc+Cgk8a2V5PlBST0pFQ1RfSUQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGI8L3N0cmluZz4KCTxrZXk+U1RPUkFHRV9CVUNLRVQ8L2tleT4KCTxzdHJpbmc+c2VmcmEtNWY3MGIuZmlyZWJhc2VzdG9yYWdlLmFwcDwvc3RyaW5nPgoJPGtleT5JU19BRFNfRU5BQkxFRDwva2V5PgoJPGZhbHNlPjwvZmFsc2U+Cgk8a2V5PklTX0FOQUxZVElDU19FTkFCTEVEPC9rZXk+Cgk8ZmFsc2U+PC9mYWxzZT4KCTxrZXk+SVNfQVBQSU5WSVRFX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfR0NNX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+SVNfU0lHTklOX0VOQUJMRUQ8L2tleT4KCTx0cnVlPjwvdHJ1ZT4KCTxrZXk+R09PR0xFX0FQUF9JRDwva2V5PgoJPHN0cmluZz4xOjQ5MDkwNjg4MjU4MTppb3M6Y2E2MzgzNzJhZjU2MmRiZjY2NzQxYzwvc3RyaW5nPgo8L2RpY3Q+CjwvcGxpc3Q+
```

5. **Secure** 체크박스 체크 (환경 변수 암호화)
6. **Add** 클릭

---

## 🚀 빌드 시작

### 자동 빌드:
- `main` 브랜치에 push하면 자동으로 빌드 시작

### 수동 빌드:
1. Codemagic 대시보드에서 **Start new build** 클릭
2. **Workflow**: `ios-workflow` 선택
3. **Branch**: `main` 선택
4. **Start new build** 클릭

---

## ✅ 변경 사항

### Podfile
```ruby
# 변경 전
use_frameworks!

# 변경 후
use_frameworks! :linkage => :static
```
→ Firebase non-modular header 에러 해결

### codemagic.yaml
```yaml
# 추가된 스크립트
- name: Set up Firebase configuration
  script: |
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > ios/Runner/GoogleService-Info.plist

- name: Clean and update pods
  script: |
    cd ios
    pod deintegrate || true
    rm -rf Pods Podfile.lock
    pod install --repo-update
```
→ Firebase 설정 자동화 및 클린 빌드

---

## 📋 체크리스트

빌드하기 전에 확인:

- [ ] Codemagic에 환경 변수 `GOOGLE_SERVICE_INFO_PLIST` 추가됨
- [ ] Workflow에서 **iOS만** 선택됨
- [ ] GitHub에 최신 코드 push됨
- [ ] Bundle ID 확인: `com.sefra.sefraFlutter`

---

## 🎯 예상 결과

환경 변수 추가 후 빌드하면:

✅ **Preparing build machine** - 3분
✅ **Fetching app sources** - 2초
✅ **Installing SDKs** - 49초
✅ **Installing dependencies** - 15초
✅ **Building iOS** - 성공! 🎉
✅ **Publishing** - 4초

---

## ❓ 문제 해결

### Q: Android가 계속 빌드됩니다
**A:** Codemagic UI → Workflow settings → Build 섹션에서 Android 체크 해제

### Q: "GOOGLE_SERVICE_INFO_PLIST not found" 에러
**A:** Codemagic UI → Environment variables에서 환경 변수가 제대로 추가되었는지 확인

### Q: Pod install 실패
**A:**
1. Podfile이 최신 버전으로 업데이트되었는지 확인
2. Codemagic에서 **Clean build** 옵션 활성화

### Q: Firebase 에러가 계속 발생
**A:**
1. 환경 변수에 base64 값 **전체**가 복사되었는지 확인
2. Secure 체크박스가 체크되었는지 확인
3. Workflow에서 "Set up Firebase configuration" 스크립트가 실행되는지 로그 확인

---

## 📞 추가 지원

더 자세한 정보는:
- `SETUP_GUIDE.md`: 전체 프로젝트 설정 가이드
- `WEB_DEVELOPER_GUIDE.md`: 웹 개발자용 빠른 가이드

**Codemagic 공식 문서**: https://docs.codemagic.io/

---

**작성일**: 2025-11-05
**마지막 업데이트**: 커밋 2f2ffc0
