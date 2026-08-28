# Contributing

Thanks for looking at DeskPet! 🐧
Everything from typo fixes to new outfits and animations is welcome.

*한국어로 이슈나 PR 을 남기셔도 전혀 문제 없습니다. 편한 언어로 써 주세요.*

---

## Setup

- macOS 13+
- Swift 6 toolchain (Xcode or just Command Line Tools)

Command Line Tools alone is enough — everything here works without full Xcode.

```bash
git clone https://github.com/chaeyeon-2/DeskPet.git
cd DeskPet

swift build
swift run DeskPetTests          # unit tests
./Scripts/build_app.sh          # build DeskPet.app
open build/DeskPet.app
```

## Before opening a PR

```bash
swift build                                   # 1. builds clean
swift run DeskPetTests                        # 2. all unit tests pass
./.build/debug/DeskPet --selftest ./selftest  # 3. real-window checks pass
```

Step 3 actually opens the window and verifies transparency, dragging, position
persistence, typing reaction, gaze tracking and speech bubbles, then writes PNG
captures to `./selftest/`. **If you changed the artwork, attach those PNGs to the
PR** — it makes review much easier.

## Layout

```
Sources/
├─ DeskPetCore/    Pure logic, no AppKit — all of it testable
└─ DeskPetApp/     AppKit / SwiftUI (window, menu bar, permissions, key monitoring)
Tests/             Unit tests
Scripts/           .app bundle + release packaging
```

**Rule of thumb: anything that doesn't need the screen belongs in `DeskPetCore`.**
That's what makes it testable. Follow the shape of `PetBrain`, which takes its clock
and randomness as injected values so tests can drive it deterministically.

## Common contributions

### Add a speech line

Only `Sources/DeskPetCore/SpeechLibrary.swift` changes.

```swift
SpeechLine(id: "myLine",  ko: "새 문구",   en: "New line",       weight: 2)
SpeechLine(id: "morning", ko: "좋은 아침", en: "Morning!",       weight: 3, hours: [7, 8, 9])
```

- **Write both `ko` and `en`.** The app switches languages at runtime and a missing
  translation would show the wrong language. A test enforces this.
- `id` must be unique — it's how repeat-suppression works
- Higher `weight` shows up more often
- `hours` limits a line to certain hours; omit it for all day
- Click replies live in `pokeLines` in the same file

### Add an outfit

1. Add a case to `Outfit` in `Sources/DeskPetCore/Pose.swift`, with a `title`
   using `L10n.t("한국어", "English")`
2. Add a draw function to the `switch` in `CharacterSprite.drawBody`
3. Add colors to `Palette.swift` if needed
4. Add a case to the sleeve colour/length `switch` in `drawLimb`

The menu bar picks it up **automatically** — no extra wiring.

Printing text on clothes? Use `MicroFont`. The chest is 21 pixels wide and the arms
cover the sides, so the usable width is the middle **15 pixels**. Long words get
split across lines (`I ♥` / `KIX` / `LAB`).

### Add an animation

1. Add a case to `PetState`
2. Define frames in `AnimationLibrary.animation(for:)` — frames are just `Pose` values
3. Decide in `PetBrain` when the state is entered
4. Add a test for that condition

You never hand-draw frames. Changing pose parameters is the whole job.

### Check your artwork

```bash
./.build/debug/DeskPet --export-sprites ./out --scale 8
open ./out/_all_states.png    # every state
open ./out/_outfits.png       # outfit comparison
```

## Please keep: the privacy promise

This is the app's core commitment. **PRs that break it won't be merged.**

- Never read key **content** (`characters`, `keyCode`, `modifierFlags`).
  The only thing passed along is *when* a key was pressed —
  see `registerKeystroke(at:)`.
- Never read the frontmost app, window titles or document contents.
- **Never add a network request.** This app is fully local.
- No analytics, telemetry or crash-reporting SDKs.

## Style

- Existing comments are in Korean; new Korean or English comments are both fine,
  and we'll tidy them up together in review.
- Explain **why**, not what — especially for pixel coordinates. Without a reason
  written down, nobody can safely change them later.
- 4-space indentation; match the surrounding file.

## Sending a PR

1. Fork and branch (`git checkout -b my-outfit`)
2. Make the three checks above pass
3. Attach screenshots if you changed anything visual
4. Open the PR

New here? Look for issues labelled `good first issue`.

## Questions

Open an issue — in whichever language you prefer.
