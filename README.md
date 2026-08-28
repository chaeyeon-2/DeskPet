<div align="center">

<img src="docs/icon.png" width="120" alt="DeskPet">

# DeskPet 🐧

**macOS 화면 위에 늘 떠 있는 작은 픽셀아트 데스크톱 펫**

타자를 치면 같이 키보드를 두드리고, 커서를 눈으로 따라다니고,
가끔 커피를 마시거나 졸다가 화들짝 깹니다.

*A tiny pixel-art desktop pet for macOS that types along with you,
follows your cursor, and occasionally says something.*

[![CI](https://github.com/chaeyeon-2/DeskPet/actions/workflows/ci.yml/badge.svg)](https://github.com/chaeyeon-2/DeskPet/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/macOS-13%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6-orange)

<img src="docs/screenshot-idle.png" width="190" alt="대기">
<img src="docs/screenshot-typing.png" width="190" alt="타이핑">
<img src="docs/screenshot-bubble.png" width="190" alt="말풍선">
<img src="docs/screenshot-puffer.png" width="190" alt="주황 패딩">

</div>

## 설치

```bash
git clone https://github.com/chaeyeon-2/DeskPet.git
cd DeskPet
./Scripts/build_app.sh
open build/DeskPet.app
```

실행하면 **Dock에는 안 뜨고 메뉴 막대 오른쪽에 얼굴 아이콘**이 생깁니다.
캐릭터는 화면 오른쪽 아래에 나타나고, 드래그해서 옮기면 위치가 저장됩니다.

타이핑을 따라 하게 하려면 권한 하나만 켜 주세요.

> **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용** 에서 `DeskPet` 켜기
> (첫 실행 때 안내창이 뜹니다. 안 켜도 나머지 동작은 전부 됩니다.)

계속 쓰시려면 `build/DeskPet.app` 을 `/Applications` 로 옮기고
메뉴에서 `로그인 시 자동 실행` 을 켜세요.

## 이런 앱입니다

- 🖥️ **100% 로컬 동작** · 네트워크 요청 **0건** · 외부 API 없음
- 🔒 키 입력의 **내용은 절대 읽지 않습니다** — "키가 눌린 시각"만 씁니다
- 🎨 **코드로 그리는 픽셀아트** — 이미지 파일 없이 그려서 어떤 배율에서도 선명합니다
- 👕 **옷 4벌** · 🎬 **11가지 상태**
- 🖱️ 캐릭터 픽셀 위에서만 클릭을 받아 **다른 앱 사용을 방해하지 않습니다**

<div align="center">
<img src="docs/outfits.png" width="620" alt="옷 4벌">
<br><sub>옷 4벌 × 상태별 모습</sub>
</div>

## 쓰는 법

캐릭터를 **드래그**하면 옮겨지고, **클릭**하면 놀라고,
**머리를 연속 3번** 클릭하면 잠깐 삐집니다.

메뉴 막대 얼굴 아이콘에서:

| 항목 | 설명 |
|---|---|
| 캐릭터 보이기/숨기기 | 숨기면 애니메이션 타이머까지 멈춰 CPU를 쓰지 않습니다 |
| 크기 | 작게(96pt) / 보통(144pt) / 크게(192pt) |
| 옷 | 파란 체크 셔츠 / 주황 패딩 / I ♥ KIXLAB 티셔츠 / LG 트윈스 유니폼 |
| 말풍선 · 말풍선 빈도 | 끄기 / 드물게 · 보통 · 자주 |
| 소리 | 타자 소리 (기본 꺼짐) |
| 로그인 시 자동 실행 | |
| 입력 감지 권한 | 현재 상태 표시 + 시스템 설정 열기 |
| 위치 초기화 · 종료 | |

<details>
<summary><b>캐릭터 상태 11가지</b></summary>

<br>

| 상태 | 언제 |
|---|---|
| `idle` | 기본 — 천천히 숨쉬기 |
| `blink` | 3~7초마다 눈 깜빡임 |
| `lookLeft` / `lookRight` | 커서가 가까이 오면 눈과 고개로 따라보기, 가끔 고개 갸웃 |
| `adjustGlasses` | 가끔 손을 올려 안경 고쳐 쓰기 |
| `typingSlow` / `typingFast` | 타이핑 중 (초당 4타 이상이면 빠른 손) |
| `drinkCoffee` | 가끔 컵을 들어 커피 마시기 |
| `sleepy` | 오래 조용하면 꾸벅꾸벅 → 끝나면 `surprised` 로 화들짝 |
| `surprised` | 캐릭터를 클릭했을 때 (안경이 살짝 삐뚤어짐) |
| `sulking` | 머리를 연속 3번 클릭했을 때 |

특수 동작은 한 번에 하나만 실행되고, 사이에 최소 9초 이상 쉽니다.

<img src="docs/states.png" width="620" alt="상태별 프레임">

</details>

## 커스터마이즈

### 말풍선 문구 바꾸기

**`Sources/DeskPetCore/SpeechLibrary.swift`** 한 파일만 고치면 됩니다.

```swift
public static let lines: [SpeechLine] = [
    SpeechLine(id: "hmm",    text: "흠…",          weight: 3),
    SpeechLine(id: "coffee", text: "커피 마실래?",  weight: 2),
    SpeechLine(id: "lunch",  text: "오늘 점심은?",  weight: 4, hours: [11, 12, 13]),
]
```

- `weight` : 클수록 자주 나옴 (`딴짓하니?` 는 0.4로 가장 드물게)
- `hours` : 그 시간대에만 나오는 문구 (없으면 하루 종일)
- 클릭했을 때의 대꾸는 같은 파일 `pokeLines`
- 표시 간격은 같은 파일 `SpeechFrequency` (드물게 / 보통 / 자주)

### 그림 바꾸기

캐릭터는 코드로 그리기 때문에 이미지 파일이 없습니다. 두 가지 방법으로 바꿀 수 있습니다.

**PNG로 교체 (재빌드 불필요)** — 원본 캔버스는 **64 × 48 픽셀**입니다.

```bash
# 1. 현재 그림 뽑아보기
./build/DeskPet.app/Contents/MacOS/DeskPet --export-sprites ~/Desktop/Sprites --scale 4

# 2. 고친 PNG를 여기에 같은 이름으로 넣기
#    ~/Library/Application Support/DeskPet/Sprites/
#      idle_0.png, typingFast_2.png, orangePuffer_idle_0.png ...
```

파일 이름은 `<상태>_<프레임>.png`, 기본 옷이 아니면 앞에 옷 이름을 붙입니다.
없는 파일은 기본 그림이 그대로 쓰입니다. (`Sources/DeskPetApp/SpriteImageProvider.swift`)

**코드 직접 수정**

| 파일 | 무엇을 |
|---|---|
| `DeskPetCore/Palette.swift` | 색 |
| `DeskPetCore/CharacterSprite.swift` | 머리·안경·옷·키보드·책상·컵 그리는 코드 |
| `DeskPetCore/Pose.swift` | 한 프레임의 자세 파라미터 + `Outfit` |
| `DeskPetCore/AnimationLibrary.swift` | 상태별 프레임과 지속 시간 |
| `DeskPetCore/MicroFont.swift` | 옷에 글자를 찍는 3×5 픽셀 폰트 |

프레임을 손으로 찍지 않고 **자세 값(`Pose`)만 바꾸면 새 동작이 됩니다.**
확대는 항상 nearest-neighbor 라서 어떤 배율에서도 픽셀이 흐려지지 않습니다.

## 개발

```bash
swift build
swift run DeskPetTests                        # 단위 테스트 72개
./.build/debug/DeskPet --selftest ./selftest  # 실제 창을 띄우는 점검 37개 (+ 창 모습 PNG)
```

```
Sources/
├─ DeskPetCore/    화면과 무관한 순수 로직 — 전부 테스트 가능
│    CharacterSprite · Pose · AnimationLibrary · PetState   그림과 애니메이션
│    PetBrain · TypingTracker · GazeSolver                  상태 머신
│    SpeechLibrary · SpeechDirector                         말풍선
│    PixelCanvas · Palette · MicroFont · AppIcon            픽셀 엔진
│    ScreenPlacement · PetSize · SpriteExport
└─ DeskPetApp/     AppKit / SwiftUI
     PetPanel · PetWindowController · PetView · PetViewModel
     KeyActivityMonitor · MenuBarController · PermissionOnboarding
     LaunchAtLogin · SoundPlayer · Preferences · SelfTest · Diagnose
```

**화면에 의존하지 않는 로직은 전부 `DeskPetCore` 에 둡니다.** 그래야 테스트할 수 있습니다.

> Xcode 없이 Command Line Tools 만 있으면 `XCTest` 를 쓸 수 없어서,
> 같은 사용법(`XCTestCase` + `XCTAssert*`)을 흉내 낸 러너를 `Sources/TinyTest` 에 넣었습니다.
> Xcode 가 있으면 `import TinyTest` 를 `import XCTest` 로 바꾸고
> `Package.swift` 의 타깃을 `.testTarget` 으로 되돌리면 `swift test` 로도 돌아갑니다.

## 배포

```bash
./Scripts/package.sh
```

`dist/` 에 **유니버설 바이너리**(Apple Silicon + Intel) DMG / ZIP 과
설치 안내문을 넣은 `DeskPet-share.zip` 이 만들어집니다.
서명 후 **DMG 안의 앱까지 서명 검증**을 자동으로 확인합니다.

개발자 계정이 있으면 정식 서명 + 공증까지 자동으로 처리합니다.

```bash
xcrun notarytool store-credentials deskpet-notary \
  --apple-id you@example.com --team-id TEAMID --password 앱-암호

DESKPET_SIGN_ID="Developer ID Application: 이름 (TEAMID)" \
DESKPET_NOTARY_PROFILE="deskpet-notary" ./Scripts/package.sh
```

계정이 없으면 ad-hoc 서명이라 받는 사람이 첫 실행 때
**우클릭 → 열기** 를 한 번 해야 합니다.

## 문제가 생겼을 때

**타이핑을 안 따라 해요**

```bash
/Applications/DeskPet.app/Contents/MacOS/DeskPet --diagnose /tmp/deskpet.txt
# 20초간 키를 쳐 본 뒤
cat /tmp/deskpet.txt
```

`AXIsProcessTrusted: false` 면 손쉬운 사용 권한 문제입니다.
분명히 켰는데도 `false` 라면 **서명이 깨졌을 가능성**이 큽니다.

```bash
codesign --verify --strict build/DeskPet.app
```

`resource fork, Finder information, or similar detritus not allowed` 가 나오면
Finder 가 붙인 확장 속성 때문에 서명 검증이 실패한 것이고,
**이 경우 macOS 는 권한 토글을 켜도 무시합니다.**

```bash
xattr -cr /Applications/DeskPet.app   # 확장 속성만 제거 (서명 해시는 그대로 → 권한 유지됨)
```

앱을 **다시 빌드하면** ad-hoc 서명 해시가 바뀌어 권한이 풀립니다.
시스템 설정에서 DeskPet 을 `−` 로 지웠다가 `+` 로 다시 추가하세요.

## 개인정보

이 앱의 가장 중요한 약속입니다.

- 사용하는 것은 **"키가 눌렸다는 사실"과 "마지막 입력 시각"뿐**입니다.
- 어떤 글자를 눌렀는지(`characters`), 어떤 키인지(`keyCode`), 어떤 앱을 쓰는지,
  문서 내용은 **읽지도 저장하지도 않습니다.** 코드상 그런 값이 전달될 통로 자체가
  없습니다 — `PetBrain.registerKeystroke(at:)` 는 시각 하나만 받습니다.
- 네트워크 요청을 전혀 하지 않습니다.
- 암호 입력창처럼 macOS 가 **보안 입력(Secure Input)** 을 켠 상태에서도
  멈추지 않고 대기 동작으로 넘어갑니다.

## 기여하기

새 옷, 새 동작, 새 말풍선 문구 모두 환영합니다.
자세한 내용은 **[CONTRIBUTING.md](CONTRIBUTING.md)** 를 봐 주세요.

| 하고 싶은 것 | 고칠 곳 |
|---|---|
| 말풍선 문구 추가 | `SpeechLibrary.swift` 에 한 줄 |
| 새 옷 만들기 | `Outfit` 에 case 하나 + `drawBody` 에 함수 하나 (메뉴 자동 등록) |
| 새 동작 만들기 | `PetState` + `AnimationLibrary` 에 프레임(=Pose 값) 정의 |

## 라이선스

[MIT License](LICENSE) — 자유롭게 쓰고, 고치고, 배포하셔도 됩니다.

다만 아래 두 가지는 **코드 라이선스와 별개**입니다.

- **캐릭터 얼굴**은 실존 인물의 사진을 참고해 만든 픽셀 캐릭터입니다.
  저장소에 원본 사진은 없지만, 특정 인물을 알아볼 수 있는 캐릭터를
  상업적으로 쓰거나 그 사람을 사칭하는 데 쓰지 말아 주세요.
- **LG 트윈스 유니폼**은 팬이 만든 픽셀 단순화 버전입니다.
  구단명과 유니폼 디자인은 해당 구단의 자산이니 개인용·비상업용으로만 써 주세요.

---

<sub>참고 사진은 디자인 참고용으로만 썼고, 인물 사진은 저장소에 포함되어 있지 않습니다.
출처가 불분명한 인터넷 이미지도 사용하지 않았습니다.</sub>
