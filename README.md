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

<img src="docs/screenshot-idle.png" width="200" alt="대기">
<img src="docs/screenshot-typing.png" width="200" alt="타이핑">
<img src="docs/screenshot-bubble.png" width="200" alt="말풍선">
<img src="docs/screenshot-puffer.png" width="200" alt="주황 패딩">

</div>

## 이런 앱입니다

- 🖥️ **100% 로컬 동작** · 네트워크 요청 **0건** · 외부 API 없음
- 🎨 **직접 그린 픽셀아트** — 이미지 파일 없이 코드로 그려서 어떤 배율에서도 선명합니다
- 👕 **옷 4벌** — 파란 체크 셔츠 / 주황 패딩 / I ♥ KIXLAB 티셔츠 / LG 트윈스 유니폼
- 🎬 **11가지 상태** — 숨쉬기, 눈 깜빡임, 커서 따라보기, 안경 고쳐 쓰기, 타이핑, 커피, 졸기, 놀람, 삐짐
- 🪟 Dock 아이콘 없이 **메뉴 막대에서만** 동작 (LSUIElement)
- 🖱️ 캐릭터 픽셀 위에서만 클릭을 받아 **다른 앱 사용을 방해하지 않습니다**
- 🔒 키 입력의 **내용은 절대 읽지 않습니다** (자세히는 [개인정보](#개인정보에-대해))

<div align="center">
<img src="docs/outfits.png" width="620" alt="옷 4벌">
<br><sub>옷 4벌 × 상태별 모습</sub>
</div>

---

## 1. 빌드하기

필요한 것: macOS 13 이상, Swift 6 툴체인(Xcode 또는 Command Line Tools)

```bash
cd DeskPet
./Scripts/build_app.sh          # build/DeskPet.app 생성 (release + ad-hoc 서명)
./Scripts/build_app.sh --debug  # 디버그 빌드
```

## 2. 실행하기

```bash
open build/DeskPet.app
```

- 실행하면 **Dock에는 아무것도 안 뜨고**, 메뉴 막대 오른쪽에 작은 얼굴 아이콘이 생깁니다.
- 캐릭터는 처음에 주 화면 오른쪽 아래에 나타납니다.
- 캐릭터를 **마우스로 끌어서** 원하는 곳에 두면 위치가 저장되고, 다음에 켤 때 그 자리에 나옵니다.
- 캐릭터를 **클릭**하면 놀라고, **머리를 연속으로 세 번** 클릭하면 잠깐 삐집니다.
- 종료: 메뉴 막대 아이콘 → `DeskPet 종료` (⌘Q)

앱을 항상 쓰고 싶다면 `build/DeskPet.app` 을 `/Applications` 로 옮긴 뒤
메뉴에서 `로그인 시 자동 실행`을 켜세요.

## 3. macOS 권한 허용하기

캐릭터가 **타이핑을 따라 하려면** 손쉬운 사용(입력 감지) 권한이 하나 필요합니다.

1. 처음 실행하면 왜 필요한지 안내하는 창이 뜹니다 → `시스템 설정 열기`
2. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용** 에서 `DeskPet` 을 켭니다
3. 권한을 켜면 앱이 3초 안에 스스로 알아채고 바로 타이핑 반응을 시작합니다 (재시작 불필요)

나중에 켜고 싶으면 메뉴 막대 → `입력 감지 권한 허용하기…` 를 누르세요.

> **권한을 주지 않아도 앱은 그대로 잘 동작합니다.** 타이핑 반응만 빠지고
> 숨쉬기·눈 깜빡임·커서 응시·커피·졸기 같은 대기 동작은 전부 그대로 나옵니다.
> 암호 입력창처럼 macOS가 **보안 입력(Secure Input)** 을 켠 상태에서도 멈추지 않고 대기 동작으로 넘어갑니다.

### 개인정보에 대해

- 앱이 사용하는 것은 **"키가 눌렸다는 사실"과 "마지막 입력 시각"뿐**입니다.
- 어떤 글자를 눌렀는지(`characters`), 어떤 키인지(`keyCode`), 어떤 앱을 쓰는지, 문서 내용은
  **읽지도 저장하지도 않습니다.** 코드상 그런 값이 전달될 통로 자체가 없습니다
  (`PetBrain.registerKeystroke(at:)` 는 시각 하나만 받습니다).
- 네트워크 요청을 전혀 하지 않습니다.

## 4. 메뉴 막대 기능

| 항목 | 설명 |
|---|---|
| 캐릭터 보이기/숨기기 | 숨기면 애니메이션 타이머까지 멈춰 CPU를 쓰지 않습니다 |
| 크기 | 작게(96pt) / 보통(144pt) / 크게(192pt) — 정수 배율만 써서 픽셀이 뭉개지지 않습니다 |
| 옷 | 파란 체크 셔츠 / 주황 패딩 / I ♥ KIXLAB 티셔츠 / LG 트윈스 유니폼 — 선택이 저장됩니다 |
| 소리 | 타자 소리·클릭 소리 (기본 꺼짐, macOS 기본 사운드만 사용) |
| 말풍선 | 말풍선 표시 켜기/끄기 |
| 말풍선 빈도 | 드물게 / 보통(기본) / 자주 — 얼마나 수다스러운지 |
| 로그인 시 자동 실행 | `SMAppService` 로 등록/해제 |
| 입력 감지 권한 허용하기… | 현재 권한 상태 표시 + 시스템 설정 열기 |
| 위치 초기화 | 캐릭터를 주 화면 오른쪽 아래로 되돌립니다 |
| DeskPet 종료 | ⌘Q |

## 5. 캐릭터 상태

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

특수 동작은 **한 번에 하나만** 실행되고, 사이에 최소 9초 이상 쉽니다.

---

## 6. 🔧 말풍선 문구 바꾸기

**`Sources/DeskPetCore/SpeechLibrary.swift`** 한 파일만 고치면 됩니다.

```swift
public static let lines: [SpeechLine] = [
    SpeechLine(id: "hmm",       text: "흠…",          weight: 3),
    SpeechLine(id: "coffee",    text: "커피 마실래?",  weight: 2),
    SpeechLine(id: "lateNight", text: "아직도 안 자?", weight: 3, lateNightOnly: true),
]
```

- `text` : 화면에 나오는 문구
- `weight` : 클수록 자주 나옴 (예: `딴짓하니?` 는 0.4로 가장 드물게)
- `lateNightOnly` : 늦은 밤(23시~새벽 5시)에만 나오는 문구

캐릭터를 클릭했을 때 나오는 짧은 대꾸는 같은 파일의 `pokeLines` 에 있습니다.

```swift
public static let pokeLines: [SpeechLine] = [
    SpeechLine(id: "poke.why", text: "왜?",  weight: 3),
    SpeechLine(id: "poke.hi",  text: "yup! happy to chat!", weight: 2),
]
```

표시 빈도는 메뉴 막대 → `말풍선 빈도` 에서 세 단계로 바꿀 수 있고,
각 단계의 값은 같은 파일 `SpeechFrequency` 에 있습니다.

```swift
case .normal:                        // 기본값
    t.idleThreshold = 45             // 45초 쉬면 후보가 됨
    t.checkInterval = 12
    t.chancePerCheck = 0.40
```

세부 기본값은 같은 파일의 `SpeechTuning` 에서 조절합니다.

```swift
public var idleThreshold: TimeInterval = 180   // 입력 없는 지 3분 지나야 후보가 됨
public var chancePerCheck: Double = 0.18       // 검사할 때마다 뜰 확률(낮을수록 조용함)
public var perLineCooldown: TimeInterval = 900 // 같은 문구는 최소 15분 뒤에 다시
public var globalCooldown: TimeInterval = 120  // 아무 문구나 연달아 나오지 않게
public var minDuration: TimeInterval = 3       // 말풍선이 3~5초 떠 있다 사라짐
public var maxDuration: TimeInterval = 5
```

## 7. 🎨 이미지 자산 바꾸기

캐릭터 그림은 **코드로 그리는 방식**이라 PNG 파일이 없어도 동작하고,
원하면 **PNG로 통째로 갈아끼울 수도** 있습니다. 두 가지 방법 다 지원합니다.

### 방법 A — PNG 스프라이트로 교체 (앱 재빌드 불필요)

1. 현재 그림을 먼저 뽑아 크기/프레임 수를 확인합니다.

   ```bash
   ./build/DeskPet.app/Contents/MacOS/DeskPet --export-sprites ~/Desktop/DeskPetSprites --scale 4
   ```

   `idle_0.png`, `typingFast_2.png` … 같은 파일과 전체 모아보기 `_all_states.png` 가 생깁니다.
   원본 캔버스는 **64 × 48 픽셀**입니다.

2. 그림을 고쳐서 아래 폴더에 같은 이름으로 넣습니다.

   ```
   ~/Library/Application Support/DeskPet/Sprites/
     idle_0.png  idle_1.png  idle_2.png  idle_3.png
     blink_0.png … typingFast_3.png … sulking_3.png
   ```

   파일 이름은 `<상태이름>_<프레임번호>.png` 이고, 상태 이름은 위 5번 표와 같습니다.
   주황 패딩용 그림은 앞에 옷 이름을 붙입니다 → `orangePuffer_idle_0.png`
   넣어 둔 파일이 있으면 그 그림이 우선 사용되고, 없는 상태는 기본 그림이 그대로 쓰입니다.
   (관련 코드: `Sources/DeskPetApp/SpriteImageProvider.swift`)

> **옷에 글자 넣기**: 가슴 폭이 21픽셀뿐이고 양팔이 좌우를 가려서
> 실제로 쓸 수 있는 폭은 가운데 15픽셀입니다. 그래서 긴 단어는
> `MicroFont` 로 여러 줄에 나눠 찍습니다 (`I ♥` / `KIX` / `LAB`).
>
> 옷을 새로 추가하려면 `Pose.swift` 의 `Outfit` 에 항목을 하나 넣고
> `CharacterSprite.drawBody` 의 `switch` 에 그리는 함수를 추가하면
> 메뉴에도 자동으로 나타납니다.

### 방법 B — 코드로 그린 픽셀아트 직접 수정

| 파일 | 무엇을 고치나 |
|---|---|
| `Sources/DeskPetCore/Palette.swift` | 색 (머리·피부·안경테·셔츠 색 등) |
| `Sources/DeskPetCore/CharacterSprite.swift` | 머리 모양, 앞머리 가르마 선, 눈썹, 안경, 옷(`drawCheckShirt` / `drawPuffer` / `drawKixlabTee` / `drawLGUniform`), 키보드, 책상, 컵 |
| `Sources/DeskPetCore/MicroFont.swift` | 옷에 글자를 찍는 3×5 픽셀 폰트 (I ♥ KIXLAB, LG TWINS) |
| `Sources/DeskPetCore/Pose.swift` | 한 프레임을 표현하는 파라미터(눈 뜬 정도, 시선, 고개 기울기, 손 위치, 옷 …) |
| `Sources/DeskPetCore/AnimationLibrary.swift` | 상태별 프레임 구성과 프레임 지속 시간 |

프레임을 손으로 찍지 않고 **자세 값(Pose)만 바꾸면 새 동작이 생기는 구조**라
`AnimationLibrary` 에 프레임 몇 줄만 추가하면 동작을 늘릴 수 있습니다.

확대는 항상 nearest-neighbor 로만 하기 때문에 어떤 배율에서도 픽셀이 흐려지지 않습니다.

---

## 8. 테스트

```bash
swift run DeskPetTests                       # 순수 로직 단위 테스트 (52개)
./.build/debug/DeskPet --selftest ./selftest # 실제 창을 띄워 동작 점검 (33개) + 창 모습 PNG 저장
```

> Xcode 없이 Command Line Tools 만 있는 환경에서는 `XCTest` 를 쓸 수 없어서,
> 같은 사용법(`XCTestCase` + `XCTAssert*`)을 그대로 흉내 낸 작은 러너를
> `Sources/TinyTest` 에 직접 넣었습니다. Xcode가 설치된 환경이면
> `Tests/DeskPetCoreTests` 의 `import TinyTest` 를 `import XCTest` 로 바꾸고
> `Package.swift` 의 타깃을 `.testTarget` 으로 되돌리면 `swift test` 로도 그대로 돌아갑니다.

## 9. 프로젝트 구조

```
DeskPet/
├─ Package.swift
├─ Scripts/build_app.sh          .app 번들 생성 + ad-hoc 서명
├─ Resources/Info.plist          LSUIElement 등 앱 설정
├─ Sources/
│  ├─ DeskPetCore/               ← 화면과 무관한 순수 로직 (전부 테스트 대상)
│  │   Palette.swift             팔레트
│  │   PixelCanvas.swift         픽셀 버퍼 + 그리기 도구 + PNG 저장
│  │   CharacterSprite.swift     캐릭터를 그리는 곳
│  │   Pose.swift                한 프레임의 자세 파라미터
│  │   AnimationLibrary.swift    상태별 애니메이션
│  │   PetState.swift            상태 정의
│  │   PetBrain.swift            상태 머신 (무엇을 언제 할지)
│  │   TypingTracker.swift       "키가 눌린 시각"만 다루는 추적기
│  │   GazeSolver.swift          커서 → 시선 계산
│  │   SpeechLibrary.swift       ★ 말풍선 문구/간격
│  │   SpeechDirector.swift      말풍선을 언제 띄울지
│  │   ScreenPlacement.swift     멀티 모니터 위치 보정
│  │   PetSize.swift             크기(정수 배율)
│  │   SpriteExport.swift        PNG 내보내기
│  ├─ DeskPetApp/                ← AppKit / SwiftUI 앱
│  │   main.swift                진입점 (--export-sprites, --selftest)
│  │   AppDelegate.swift
│  │   PetPanel.swift            투명 창 + 픽셀 단위 클릭 통과
│  │   PetWindowController.swift 위치/크기/애니메이션 루프
│  │   PetViewModel.swift        화면 상태
│  │   PetView.swift             SwiftUI 캐릭터 + 말풍선
│  │   SpriteImageProvider.swift ★ PNG 교체 지원
│  │   KeyActivityMonitor.swift  키 입력 "사실"만 감지
│  │   MenuBarController.swift   메뉴 막대
│  │   PermissionOnboarding.swift 권한 안내
│  │   LaunchAtLogin.swift / SoundPlayer.swift / Preferences.swift
│  │   SelfTest.swift            --selftest 점검
│  └─ TinyTest/                  XCTest 대체 러너
└─ Tests/DeskPetCoreTests/       단위 테스트
```

## 10. 다른 사람에게 배포하기

```bash
./Scripts/package.sh
```

한 번 실행하면 `dist/` 에 아래가 만들어집니다 (1분 남짓).

| 파일 | 설명 |
|---|---|
| `DeskPet-1.0.dmg` | 드래그해서 설치하는 디스크 이미지 (Applications 바로가기 포함) |
| `DeskPet-1.0.zip` | 압축본 |

- **유니버설 바이너리** (Apple Silicon + Intel 둘 다 실행)
- 캐릭터 얼굴로 만든 **앱 아이콘(.icns)** 자동 생성
- 서명 후 **DMG 안의 앱까지 서명 검증**을 자동으로 확인합니다
  (`hdiutil` 이 앱 번들에 붙이는 `com.apple.FinderInfo` 를 지워 줍니다 —
   이게 남으면 받는 사람 쪽에서 손쉬운 사용 권한이 동작하지 않습니다)

### 개발자 계정 없이 배포 (무료)

지금 만들어지는 파일이 여기에 해당합니다. ad-hoc 서명이라 받는 사람이 처음 열 때
"확인되지 않은 개발자" 경고가 뜹니다. 함께 안내해 주세요.

> 1. DMG 를 열고 DeskPet 을 응용 프로그램 폴더로 드래그
> 2. **응용 프로그램 폴더에서 DeskPet 을 우클릭 → 열기 → 열기** (첫 실행만)
> 3. 시스템 설정 → 개인정보 보호 및 보안 → **손쉬운 사용** 에서 DeskPet 켜기

### 개발자 계정으로 배포 (연 $99, 경고 없음)

Apple Developer Program 에 가입해 **Developer ID Application** 인증서를 받은 뒤:

```bash
# 공증 자격을 한 번만 저장
xcrun notarytool store-credentials deskpet-notary \
  --apple-id you@example.com --team-id TEAMID --password 앱-암호

DESKPET_SIGN_ID="Developer ID Application: 이름 (TEAMID)" \
DESKPET_NOTARY_PROFILE="deskpet-notary" \
./Scripts/package.sh
```

정식 서명 + 공증(notarization) + 스테이플까지 자동으로 처리해서,
받는 사람이 **경고 없이 그냥 열 수 있는** DMG 가 나옵니다.

### 소스로 배포 (GitHub 등)

가장 간단합니다. 저장소를 올리고 받는 사람이 직접 빌드하게 하면
서명/공증 문제가 아예 없습니다.

```bash
git clone <저장소>
cd DeskPet && ./Scripts/build_app.sh && open build/DeskPet.app
```

## 11. 문제가 생겼을 때

**타이핑을 안 따라 해요**

```bash
./build/DeskPet.app/Contents/MacOS/DeskPet --diagnose /tmp/deskpet.txt
# 20초간 키를 쳐 본 뒤
cat /tmp/deskpet.txt
```

- `손쉬운 사용(AXIsProcessTrusted): false` → 권한 문제입니다. 아래를 확인하세요.
- 권한을 분명히 켰는데도 `false` 라면 **서명이 깨졌을 가능성**이 큽니다.

  ```bash
  codesign --verify --strict build/DeskPet.app
  ```

  `resource fork, Finder information, or similar detritus not allowed` 가 나오면
  Finder 가 붙인 확장 속성 때문에 서명 검증이 실패한 것이고,
  이 경우 macOS 는 **권한 토글을 켜도 무시합니다.** 다시 빌드하면 해결됩니다
  (`build_app.sh` 가 서명 전에 `xattr -cr` 로 정리하고 검증까지 합니다).

**서명이 깨졌을 때 권한을 잃지 않고 고치는 법**

```bash
xattr -cr /Applications/DeskPet.app     # 확장 속성만 지움 (서명 해시는 그대로)
codesign --verify --strict /Applications/DeskPet.app
```

`xattr -cr` 은 서명 자체를 바꾸지 않기 때문에 **이미 허용한 권한이 유지됩니다.**
(다시 빌드하면 서명 해시가 바뀌어 권한을 다시 켜야 합니다.)

**앱을 다시 빌드하면 권한이 풀립니다.**
ad-hoc 서명이라 빌드할 때마다 서명 해시가 바뀝니다. 재빌드 후에는
시스템 설정 → 손쉬운 사용에서 DeskPet 을 `−` 로 지웠다가 `+` 로 다시 추가하세요.

## 12. 기여하기

기여를 환영합니다! 새 옷, 새 동작, 새 말풍선 문구 모두 좋습니다.
자세한 내용은 **[CONTRIBUTING.md](CONTRIBUTING.md)** 를 봐 주세요.

가장 쉽게 시작하는 방법:

| 하고 싶은 것 | 고칠 파일 |
|---|---|
| 말풍선 문구 추가 | `Sources/DeskPetCore/SpeechLibrary.swift` 에 한 줄 |
| 새 옷 만들기 | `Outfit` 에 case 하나 + `drawBody` 에 그리는 함수 하나 (메뉴에는 자동 등록) |
| 새 동작 만들기 | `PetState` + `AnimationLibrary` 에 프레임(=Pose 값) 정의 |

PR 전에 아래 세 가지만 확인해 주세요.

```bash
swift build
swift run DeskPetTests                        # 단위 테스트 72개
./.build/debug/DeskPet --selftest ./selftest  # 실제 창을 띄우는 점검 37개
```

## 13. 라이선스

[MIT License](LICENSE) — 자유롭게 쓰고, 고치고, 배포하셔도 됩니다.

다만 아래 두 가지는 **코드 라이선스와 별개**이니 참고해 주세요.

- **캐릭터 얼굴**은 실존 인물의 사진을 참고해 만든 픽셀 캐릭터입니다.
  코드는 MIT 이지만, 특정 인물을 알아볼 수 있는 캐릭터를 상업적으로 쓰거나
  그 사람을 사칭하는 데 쓰는 것은 라이선스와 무관하게 하지 말아 주세요.
  (저장소에 원본 인물 사진은 포함되어 있지 않습니다)
- **LG 트윈스 유니폼**은 팬이 만든 픽셀 단순화 버전입니다.
  구단 로고 이미지를 그대로 쓰지 않았지만, 구단명과 유니폼 디자인은 해당 구단의 자산입니다.
  개인용·비상업용으로만 써 주세요.

## 14. 만든 방식에 대해

- 캐릭터는 참고 사진을 보고 **처음부터 새로 그린 픽셀 캐릭터**입니다.
  사진을 오려 붙이거나 원본 인물 사진을 저장소에 포함하지 않았고,
  출처가 불분명한 인터넷 이미지도 쓰지 않았습니다.
- 특징(검은 가르마 머리 / 사각 안경 / 눈썹 / 파란 체크 셔츠)만 단순화해서 옮겼습니다.
- LG 트윈스 유니폼은 참고 사진을 보고 색과 배치만 픽셀로 단순화한 팬 아트입니다.
  구단 로고 이미지를 그대로 쓰지 않았고, 개인용/친구에게 나눠 쓰는 용도입니다.
