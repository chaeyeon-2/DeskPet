#!/bin/bash
# DeskPet 배포용 패키지 만들기 (유니버설 바이너리 + 아이콘 + DMG/ZIP)
#
#   ./Scripts/package.sh
#
# 애플 개발자 계정이 있다면 아래 환경변수를 주면 정식 서명/공증까지 합니다.
#   DESKPET_SIGN_ID="Developer ID Application: 홍길동 (TEAMID)" \
#   DESKPET_NOTARY_PROFILE="deskpet-notary" \
#   ./Scripts/package.sh
#
# (공증 프로필은 미리 한 번 만들어 둡니다)
#   xcrun notarytool store-credentials deskpet-notary \
#     --apple-id you@example.com --team-id TEAMID --password 앱암호
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
DIST="$ROOT/dist"
APP="$DIST/DeskPet.app"
STAGE="$DIST/stage"
SIGN_ID="${DESKPET_SIGN_ID:--}"

rm -rf "$DIST"
mkdir -p "$DIST" "$STAGE"

echo "▸ Apple Silicon(arm64) 빌드"
swift build --package-path "$ROOT" -c release --triple arm64-apple-macosx13.0 --product DeskPet >/dev/null
ARM_BIN="$(swift build --package-path "$ROOT" -c release --triple arm64-apple-macosx13.0 --show-bin-path)/DeskPet"

echo "▸ Intel(x86_64) 빌드"
swift build --package-path "$ROOT" -c release --triple x86_64-apple-macosx13.0 --product DeskPet >/dev/null
X86_BIN="$(swift build --package-path "$ROOT" -c release --triple x86_64-apple-macosx13.0 --show-bin-path)/DeskPet"

echo "▸ 유니버설 바이너리 합치기"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$ARM_BIN" "$X86_BIN" -output "$APP/Contents/MacOS/DeskPet"
lipo -info "$APP/Contents/MacOS/DeskPet"

cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

echo "▸ 앱 아이콘 생성"
ICONSET="$DIST/DeskPet.iconset"
"$ARM_BIN" --export-iconset "$ICONSET" >/dev/null
iconutil -c icns -o "$APP/Contents/Resources/AppIcon.icns" "$ICONSET"
rm -rf "$ICONSET"

echo "▸ 확장 속성 정리 + 서명"
xattr -cr "$APP"
if [[ "$SIGN_ID" == "-" ]]; then
  echo "  (개발자 인증서 없음 → ad-hoc 서명. 받는 사람이 '우클릭 → 열기' 를 한 번 해야 합니다)"
  codesign --force --sign - --timestamp=none "$APP"
else
  echo "  Developer ID 로 서명: $SIGN_ID"
  codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$APP"
fi
codesign --verify --strict --verbose=1 "$APP"

echo "▸ ZIP 만들기"
ditto -c -k --keepParent "$APP" "$DIST/DeskPet-$VERSION.zip"

echo "▸ DMG 만들기"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
RW_DMG="$DIST/.deskpet-rw.dmg"
hdiutil create -volname "DeskPet" -srcfolder "$STAGE" -ov -format UDRW "$RW_DMG" >/dev/null
rm -rf "$STAGE"

# hdiutil 이 앱 번들 최상위에 com.apple.FinderInfo 를 붙인다.
# 이게 남으면 받는 사람 쪽에서 서명 검증이 실패하고 손쉬운 사용 권한이 동작하지 않으므로
# 쓰기 가능한 상태로 마운트해서 지운 뒤 압축본으로 변환한다.
MNT="$(mktemp -d)"
hdiutil attach "$RW_DMG" -nobrowse -quiet -mountpoint "$MNT"
xattr -cr "$MNT/DeskPet.app"
if ! codesign --verify --strict "$MNT/DeskPet.app"; then
  hdiutil detach "$MNT" -quiet; rm -rf "$MNT" "$RW_DMG"
  echo "  ✗ DMG 안의 앱 서명이 깨졌습니다"; exit 1
fi
hdiutil detach "$MNT" -quiet; rmdir "$MNT" 2>/dev/null || true

hdiutil convert "$RW_DMG" -format UDZO -o "$DIST/DeskPet-$VERSION.dmg" -ov >/dev/null
rm -f "$RW_DMG"

echo "▸ DMG 안의 앱 서명 최종 확인"
MNT="$(mktemp -d)"
hdiutil attach "$DIST/DeskPet-$VERSION.dmg" -nobrowse -quiet -mountpoint "$MNT"
if codesign --verify --strict "$MNT/DeskPet.app" 2>/dev/null; then
  echo "  ✓ DMG 안의 앱 서명 유효 - 받는 사람 쪽에서도 권한이 정상 동작합니다"
  hdiutil detach "$MNT" -quiet; rmdir "$MNT" 2>/dev/null || true
else
  echo "  ✗ DMG 안의 앱 서명이 깨졌습니다"
  hdiutil detach "$MNT" -quiet; rmdir "$MNT" 2>/dev/null || true
  exit 1
fi

if [[ -n "${DESKPET_NOTARY_PROFILE:-}" ]]; then
  echo "▸ 공증(notarization) 제출 - 몇 분 걸립니다"
  xcrun notarytool submit "$DIST/DeskPet-$VERSION.dmg" --keychain-profile "$DESKPET_NOTARY_PROFILE" --wait
  xcrun stapler staple "$DIST/DeskPet-$VERSION.dmg"
  xcrun stapler staple "$APP"
  echo "  ✓ 공증 완료 - 받는 사람이 아무 경고 없이 바로 열 수 있습니다"
else
  echo "▸ 공증 건너뜀 (DESKPET_NOTARY_PROFILE 미설정)"
fi

echo "▸ 보내기용 묶음 만들기"
SHARE="$DIST/DeskPet-share"
rm -rf "$SHARE" "$DIST/DeskPet-share.zip"
mkdir -p "$SHARE"
cp "$DIST/DeskPet-$VERSION.dmg" "$SHARE/"
cp "$ROOT/Resources/INSTALL-설치방법.txt" "$SHARE/"
ditto -c -k --keepParent "$SHARE" "$DIST/DeskPet-share.zip"
rm -rf "$SHARE"

echo ""
echo "✓ 배포 파일이 준비됐습니다"
ls -lh "$DIST" | grep -E "dmg|zip" || true
