#!/bin/bash
# DeskPet.app 번들을 만든다.
#   ./Scripts/build_app.sh            → release 빌드 후 build/DeskPet.app 생성
#   ./Scripts/build_app.sh --debug    → debug 빌드
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="release"
[[ "${1:-}" == "--debug" ]] && CONFIG="debug"

echo "▸ swift build (${CONFIG})"
swift build --package-path "$ROOT" -c "$CONFIG"

# 바로 앞 빌드 결과를 사용한다. `--show-bin-path`를 위해 SwiftPM을 한 번 더
# 호출하지 않아 느린 디스크/네트워크 볼륨에서도 build.db 잠금 충돌을 피한다.
BIN="$(find "$ROOT/.build" -path "*/$CONFIG/DeskPet" -type f -perm -111 -print -quit)"
if [[ -z "$BIN" ]]; then
  echo "✗ 빌드된 DeskPet 실행 파일을 찾지 못했습니다"
  exit 1
fi
APP="$ROOT/build/DeskPet.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DeskPet"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

echo "▸ 앱 아이콘 생성"
ICONSET="$ROOT/build/DeskPet.iconset"
rm -rf "$ICONSET"
"$BIN" --export-iconset "$ICONSET" >/dev/null
iconutil -c icns -o "$APP/Contents/Resources/AppIcon.icns" "$ICONSET"
rm -rf "$ICONSET"

# 손쉬운 사용 권한이 동작하려면 서명이 "검증까지 통과"해야 한다.
# Finder 가 붙이는 확장 속성(com.apple.FinderInfo 등)이 남아 있으면 서명 검증이 실패하고,
# 그러면 시스템 설정에서 권한을 켜도 macOS 가 무시한다. 그래서 서명 전에 반드시 지운다.
echo "▸ 확장 속성 정리 (xattr)"
xattr -c "$APP"
find "$APP" -type f -exec xattr -c {} +

echo "▸ codesign (ad-hoc)"
codesign --force --sign - --timestamp=none "$APP"

echo "▸ 서명 검증"
if codesign --verify --strict --verbose=1 "$APP" 2>&1 | grep -q "valid on disk"; then
  echo "  ✓ 서명 유효 - 손쉬운 사용 권한이 정상 동작합니다"
else
  codesign --verify --strict "$APP" || { echo "  ✗ 서명 검증 실패 - 권한이 동작하지 않습니다"; exit 1; }
  echo "  ✓ 서명 유효"
fi

echo "✓ 완성: $APP"
echo "  실행: open \"$APP\""
