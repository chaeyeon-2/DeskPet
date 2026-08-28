# 기여하기 / Contributing

DeskPet 에 관심 가져 주셔서 고맙습니다! 🐧
작은 오타 수정부터 새 옷, 새 동작까지 어떤 기여든 환영합니다.

*Contributions are welcome — from typo fixes to new outfits and animations.
Korean or English, whichever you're comfortable with.*

---

## 개발 환경

- macOS 13 이상
- Swift 6 툴체인 (Xcode 또는 Command Line Tools)

Xcode 없이 Command Line Tools 만 있어도 전부 동작합니다.

```bash
git clone https://github.com/chaeyeon-2/DeskPet.git
cd DeskPet

swift build                          # 빌드
swift run DeskPetTests               # 단위 테스트 (72개)
./Scripts/build_app.sh               # DeskPet.app 만들기
open build/DeskPet.app               # 실행
```

## 확인해야 할 것 (PR 전 체크리스트)

```bash
swift build                                   # 1. 경고 없이 빌드되는가
swift run DeskPetTests                        # 2. 단위 테스트 전부 통과하는가
./.build/debug/DeskPet --selftest ./selftest  # 3. 실제 창을 띄우는 점검 통과하는가
```

3번은 실제로 창을 띄워서 투명 창·드래그·위치 저장·타이핑 반응·시선 추적·말풍선까지
확인하고, `./selftest/` 에 창 모습을 PNG 로 남깁니다. 그림을 바꿨다면 이 PNG 를
PR 에 첨부해 주시면 리뷰가 훨씬 쉬워집니다.

## 프로젝트 구조 한눈에

```
Sources/
├─ DeskPetCore/    화면과 무관한 순수 로직 — 여기 있는 건 전부 테스트 가능
└─ DeskPetApp/     AppKit / SwiftUI 앱 (창, 메뉴 막대, 권한, 입력 감지)
Tests/             단위 테스트
Scripts/           .app 번들 · 배포 패키지 만들기
```

**핵심 규칙: 화면(AppKit)에 의존하지 않는 로직은 전부 `DeskPetCore` 에 둡니다.**
그래야 테스트할 수 있습니다. `PetBrain` 처럼 시간과 난수를 주입받는 형태를 따라 주세요.

## 자주 하는 기여

### 말풍선 문구 추가

`Sources/DeskPetCore/SpeechLibrary.swift` 한 파일만 고치면 됩니다.

```swift
SpeechLine(id: "myLine", text: "새 문구", weight: 2)
SpeechLine(id: "morning", text: "좋은 아침", weight: 3, hours: [7, 8, 9])  // 시간대 한정
```

- `id` 는 겹치지 않게 지어 주세요 (같은 문구 반복 방지에 사용됩니다)
- `weight` 가 클수록 자주 나옵니다
- 클릭했을 때 나오는 대꾸는 같은 파일의 `pokeLines` 에 추가합니다

### 새 옷 만들기

1. `Sources/DeskPetCore/Pose.swift` 의 `Outfit` 에 case 추가 + `title` 작성
2. `Sources/DeskPetCore/CharacterSprite.swift` 의 `drawBody` switch 에 그리는 함수 추가
3. 필요하면 `Palette.swift` 에 색 추가
4. `drawLimb` 의 소매 색/길이 switch 에도 case 추가

메뉴 막대에는 **자동으로** 나타납니다. 별도 작업이 필요 없습니다.

옷에 글자를 넣는다면 `MicroFont` 를 쓰세요. 가슴 폭은 21픽셀이고 양팔이 좌우를
가려서 실제 쓸 수 있는 폭은 가운데 **15픽셀**입니다. 긴 단어는 여러 줄로 나눠 찍습니다.

### 새 동작(상태) 만들기

1. `PetState` 에 case 추가
2. `AnimationLibrary.animation(for:)` 에 프레임 정의 (Pose 값만 바꾸면 됩니다)
3. `PetBrain` 에서 언제 그 상태로 갈지 정합니다
4. 테스트 추가 — 어떤 조건에서 그 상태가 되는지

프레임 그림을 손으로 찍을 필요 없이 **자세 파라미터(`Pose`)만 바꾸면** 새 동작이 됩니다.

### 그림 확인하기

```bash
./.build/debug/DeskPet --export-sprites ./out --scale 8
open ./out/_all_states.png    # 모든 상태 한 장에
open ./out/_outfits.png       # 옷별 비교
```

## 지켜 주세요 — 개인정보 원칙

이 앱의 가장 중요한 약속입니다. **PR 이 이걸 어기면 머지하지 않습니다.**

- 키 입력의 **내용**(`characters`, `keyCode`, `modifierFlags`)을 읽지 않습니다.
  전달받는 것은 "키가 눌린 시각"뿐입니다 (`registerKeystroke(at:)`).
- 사용 중인 앱, 창 제목, 문서 내용을 읽지 않습니다.
- **네트워크 요청을 추가하지 않습니다.** 이 앱은 완전히 로컬에서만 동작합니다.
- 분석/통계/크래시 리포트 SDK 를 넣지 않습니다.

## 코드 스타일

- 주석은 한국어로 씁니다 (기존 코드와 맞추기 위해). 영어 PR 도 환영하며, 리뷰에서 함께 다듬습니다.
- "무엇을" 하는지가 아니라 **"왜" 그렇게 했는지**를 주석으로 남겨 주세요.
  특히 픽셀 좌표는 이유가 없으면 나중에 아무도 못 고칩니다.
- 들여쓰기 4칸, 기존 파일의 스타일을 따릅니다.

## PR 보내기

1. 저장소를 fork 하고 브랜치를 만듭니다 (`git checkout -b my-outfit`)
2. 위 체크리스트 3개를 통과시킵니다
3. 그림을 바꿨다면 스크린샷을 첨부합니다
4. PR 을 엽니다

처음이시라면 `good first issue` 라벨이 붙은 이슈부터 보시면 좋습니다.

## 질문

이슈를 열어 주세요. 편한 언어로 물어보시면 됩니다.
