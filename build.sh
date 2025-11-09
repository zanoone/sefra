#!/bin/bash

# Sefra iOS 빌드 스크립트

set -e

echo "=========================================="
echo "Sefra iOS 빌드 시작"
echo "=========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프로젝트 설정
WORKSPACE="SefraiOS.xcworkspace"
SCHEME="SefraiOS"
CONFIGURATION="Debug"

echo ""
echo "${YELLOW}1. CocoaPods 의존성 설치...${NC}"
if [ ! -f "Podfile" ]; then
    echo "${RED}❌ Podfile을 찾을 수 없습니다!${NC}"
    exit 1
fi

pod install

echo ""
echo "${YELLOW}2. GoogleService-Info.plist 확인...${NC}"
if [ ! -f "SefraiOS/GoogleService-Info.plist" ]; then
    echo "${RED}❌ GoogleService-Info.plist를 찾을 수 없습니다!${NC}"
    echo "Firebase Console에서 다운로드하여 SefraiOS/ 폴더에 추가해주세요."
    exit 1
fi

echo ""
echo "${YELLOW}3. 시뮬레이터 빌드 시작...${NC}"
xcodebuild -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
    clean build

if [ $? -eq 0 ]; then
    echo ""
    echo "${GREEN}=========================================="
    echo "✅ 빌드 성공!"
    echo "==========================================${NC}"
    echo ""
    echo "시뮬레이터 실행 명령:"
    echo "  xcrun simctl boot 'iPhone 15 Pro'"
    echo "  open -a Simulator"
else
    echo ""
    echo "${RED}=========================================="
    echo "❌ 빌드 실패"
    echo "==========================================${NC}"
    exit 1
fi
