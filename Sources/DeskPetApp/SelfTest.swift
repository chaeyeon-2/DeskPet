import AppKit
import DeskPetCore

/// `DeskPet --selftest [폴더]`
/// 실제 창을 띄운 상태에서 요구사항을 하나씩 확인하고, 창 모습을 PNG 로 저장한다.
/// (화면 녹화 권한 없이, 앱이 자기 창을 직접 그려서 저장한다)
final class SelfTest: NSObject {

    private let outputDirectory: URL
    private var results: [(name: String, passed: Bool, detail: String)] = []
    private var controller: PetWindowController!
    private let prefs: Preferences
    private let sound = SoundPlayer()
    private var steps: [(name: String, setup: () -> Void)] = []
    private var base: TimeInterval = 0

    init(outputDirectory: URL) {
        self.outputDirectory = outputDirectory
        let suite = UserDefaults(suiteName: "com.deskpet.selftest") ?? .standard
        suite.removePersistentDomain(forName: "com.deskpet.selftest")
        self.prefs = Preferences(defaults: suite)
        super.init()
    }

    private func check(_ name: String, _ passed: Bool, _ detail: String = "") {
        results.append((name, passed, detail))
        print("\(passed ? "  ✓" : "  ✗") \(name)\(detail.isEmpty ? "" : "  — \(detail)")")
    }

    func run() {
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        print("▸ DeskPet 자체 점검")

        controller = PetWindowController(prefs: prefs, sound: sound)
        controller.setVisible(true)
        controller.testStopAnimationTimer()      // 점검 동안에는 시각을 직접 넣어 준다
        base = ProcessInfo.processInfo.systemUptime

        checkWindow()
        checkPositionAndScreens()
        checkClickThrough()
        checkBehaviour()
        checkMenuAndSizes()
        buildSnapshotSteps()
        runStep(0)
    }

    // MARK: - 창

    private func checkWindow() {
        let window = controller.testWindow
        check("투명 배경의 테두리 없는 창",
              !window.isOpaque && window.backgroundColor == .clear && window.styleMask.contains(.borderless))
        check("포커스를 빼앗지 않음(비활성 패널)", !window.canBecomeKey && !window.canBecomeMain)
        check("다른 앱 위에 떠 있음(floating)", window.level == .floating)
        check("Spaces 를 옮겨도 보임", window.collectionBehavior.contains(.canJoinAllSpaces))
        check("전체 화면을 덮지 않는 작은 창",
              window.frame.width <= 260 && window.frame.height <= 300,
              "\(Int(window.frame.width))×\(Int(window.frame.height))pt")
        check("Dock 아이콘 없이 동작(accessory)", NSApp.activationPolicy() == .accessory)
        check("창이 화면에 표시됨", window.isVisible)
    }

    private func checkPositionAndScreens() {
        let screens = NSScreen.screens.map { $0.visibleFrame }
        let window = controller.testWindow
        check("첫 위치가 화면 안", screens.contains { $0.intersects(window.frame) },
              "모니터 \(screens.count)대")

        let before = window.frame.origin
        controller.testMove(by: CGSize(width: -120, height: 90))
        let after = window.frame.origin
        check("마우스 드래그로 이동",
              abs(after.x - (before.x - 120)) < 0.5 && abs(after.y - (before.y + 90)) < 0.5)

        controller.savePosition()
        let saved = prefs.savedOrigin
        check("마지막 위치 저장",
              saved.map { abs($0.x - controller.testWindow.frame.origin.x) < 1 } ?? false,
              saved.map { "(\(Int($0.x)), \(Int($0.y)))" } ?? "저장 안 됨")

        // 다시 켠 상황: 저장된 위치로 복원되는지
        let restored = PetWindowController(prefs: prefs, sound: sound)
        check("앱을 다시 켜면 위치 복원",
              abs(restored.testWindow.frame.origin.x - (saved?.x ?? -1)) < 1
              && abs(restored.testWindow.frame.origin.y - (saved?.y ?? -1)) < 1)

        controller.testSetOrigin(CGPoint(x: 99_000, y: 99_000))
        controller.clampIntoScreens()
        check("화면 밖으로 나가지 않음", screens.contains { $0.intersects(controller.testWindow.frame) })

        controller.testSetOrigin(CGPoint(x: -99_000, y: -99_000))
        controller.clampIntoScreens()
        check("모니터가 사라져도 되돌아옴", screens.contains { $0.intersects(controller.testWindow.frame) })
        controller.resetPosition()
    }

    private func checkClickThrough() {
        let content = controller.testContentView
        let sprite = content.spriteFrame
        check("캐릭터 위에서는 클릭을 받음",
              content.hitTest(CGPoint(x: sprite.midX, y: sprite.maxY - sprite.height * 0.25)) === content)
        check("투명한 곳은 클릭이 그대로 통과함",
              content.hitTest(CGPoint(x: 2, y: content.bounds.maxY - 2)) == nil
              && content.hitTest(CGPoint(x: content.bounds.maxX - 2, y: 2)) == nil)
    }

    // MARK: - 동작

    private func checkBehaviour() {
        let model = controller.model
        let head = controller.testHeadCenter

        for i in 0..<12 { model.registerKeystroke(at: base + Double(i) * 0.07) }
        model.tick(now: base + 0.85, headCenter: head, cursor: .zero)
        check("타이핑하면 캐릭터도 키보드를 두드림",
              model.currentState == .typingFast || model.currentState == .typingSlow,
              "상태=\(model.currentState.rawValue)")
        check("타이핑 중에는 책상과 키보드가 나타남",
              model.currentPose.showDesk && model.currentPose.handsOnKeyboard)

        model.tick(now: base + 3.0, headCenter: head, cursor: .zero)
        check("입력이 멈추면 대기 상태로 복귀",
              model.currentState != .typingFast && model.currentState != .typingSlow,
              "상태=\(model.currentState.rawValue)")

        var t = base + 3.2
        var rightGaze = 0, leftGaze = 0
        var turnedRight = false, turnedLeft = false
        for _ in 0..<10 {
            model.tick(now: t, headCenter: head, cursor: CGPoint(x: head.x + 220, y: head.y))
            rightGaze = max(rightGaze, model.currentPose.gazeX)
            turnedRight = turnedRight || model.currentState == .lookRight
            t += 0.1
        }
        for _ in 0..<10 {
            model.tick(now: t, headCenter: head, cursor: CGPoint(x: head.x - 220, y: head.y))
            leftGaze = min(leftGaze, model.currentPose.gazeX)
            turnedLeft = turnedLeft || model.currentState == .lookLeft
            t += 0.1
        }
        check("커서를 따라 시선과 고개가 움직임",
              rightGaze > 0 && leftGaze < 0 && turnedRight && turnedLeft,
              "눈동자 +\(rightGaze)/\(leftGaze), 고개 돌림 O")

        model.tick(now: t, headCenter: head, cursor: CGPoint(x: head.x + 5000, y: head.y))
        check("커서가 멀면 정면을 봄", model.currentPose.gazeX == 0)

        let monitor = KeyActivityMonitor()
        monitor.start()
        check("권한이 없어도 앱이 멈추지 않음", true,
              "손쉬운 사용=\(monitor.isTrusted ? "허용됨" : "아직 없음"), 보안 입력=\(monitor.isSecureInputEnabled ? "켜짐" : "꺼짐")")
        monitor.stop()
    }

    private func checkMenuAndSizes() {
        let monitor = KeyActivityMonitor()
        let pomodoro = PomodoroController(prefs: prefs, model: controller.model)
        let menuBar = MenuBarController(prefs: prefs, sound: sound,
                                        windowController: controller, keyMonitor: monitor,
                                        pomodoro: pomodoro)
        menuBar.refresh()
        check("메뉴 막대 아이콘과 메뉴 구성", true)

        for size in PetSize.allCases {
            controller.applySize(size)
            let expected = size.spriteSize.height + controller.model.bubbleAreaHeight
            check("크기 \(size.title)", abs(controller.testWindow.frame.height - expected) < 0.5,
                  "캐릭터 \(Int(size.spriteSize.height))pt")
        }
        controller.applySize(.medium)

        controller.setVisible(false)
        check("캐릭터 숨기기", !controller.testWindow.isVisible)
        controller.setVisible(true)
        controller.testStopAnimationTimer()
        check("캐릭터 보이기", controller.testWindow.isVisible)

        // 언어 전환
        for language in AppLanguage.allCases {
            L10n.setLanguage(language)
            let titles = Outfit.allCases.map(\.title) + PetSize.allCases.map(\.title)
            check("언어 \(language.rawValue) 적용", titles.allSatisfy { !$0.isEmpty })
        }
        L10n.setLanguage(.english)
        let englishOK = Outfit.orangePuffer.title == "Orange Puffer" && PetSize.small.title == "Small"
        check("영어 UI 문자열", englishOK, "옷=\(Outfit.orangePuffer.title), 크기=\(PetSize.small.title)")
        L10n.setLanguage(.korean)
        let koreanOK = Outfit.orangePuffer.title == "주황 패딩" && PetSize.small.title == "작게"
        check("한국어 UI 문자열", koreanOK)
        L10n.setLanguage(.system)

        for outfit in Outfit.allCases {
            controller.model.outfit = outfit
            controller.model.tick(now: base + 30, headCenter: controller.testHeadCenter, cursor: .zero)
            check("옷 갈아입기 - \(outfit.title)", controller.model.currentPose.outfit == outfit)
        }
        controller.model.outfit = .checkShirt

        prefs.bubblesEnabled = false
        controller.model.bubblesEnabled = false
        controller.model.showHint("가려져야 함", seconds: 5, now: base)
        check("말풍선 끄기 설정이 반영됨", controller.model.bubbleText == nil)
        prefs.bubblesEnabled = true
        controller.model.bubblesEnabled = true
    }

    // MARK: - 창 모습 저장 (SwiftUI 갱신을 기다린 뒤 캡처)

    private func buildSnapshotSteps() {
        let model = controller.model
        let head = controller.testHeadCenter

        steps = [
            ("01-idle", { model.tick(now: self.base + 40, headCenter: head, cursor: .zero) }),
            ("02-typing", {
                for i in 0..<14 { model.registerKeystroke(at: self.base + 50 + Double(i) * 0.06) }
                model.tick(now: self.base + 50.9, headCenter: head, cursor: .zero)
                self.check("타이핑 모습 캡처", model.currentState == .typingFast)
            }),
            ("03-surprised", {
                model.registerClick(onHead: true, at: self.base + 60)
                model.tick(now: self.base + 60.1, headCenter: head, cursor: .zero)
                self.check("클릭하면 놀란 표정", model.currentState == .surprised)
            }),
            ("04-bubble", {
                model.showHint("키보드 조용한데?", seconds: 30, now: self.base + 70)
                model.tick(now: self.base + 70.1, headCenter: head, cursor: .zero)
                self.check("말풍선 표시", model.bubbleText == "키보드 조용한데?")
            }),
            ("05-look-right", {
                model.tick(now: self.base + 71, headCenter: head,
                           cursor: CGPoint(x: head.x + 200, y: head.y + 120))
                self.check("말풍선이 3~5초 뒤 사라짐 규칙", SpeechLibrary.tuning.minDuration == 3
                           && SpeechLibrary.tuning.maxDuration == 5)
            }),
            ("07-puffer", {
                model.outfit = .orangePuffer
                model.tick(now: self.base + 90, headCenter: head, cursor: .zero)
            }),
            ("08-puffer-typing", {
                for i in 0..<14 { model.registerKeystroke(at: self.base + 95 + Double(i) * 0.06) }
                model.tick(now: self.base + 95.9, headCenter: head, cursor: .zero)
            }),
            ("06-bubble-gone", {
                model.tick(now: self.base + 101, headCenter: head, cursor: .zero)
                self.check("말풍선이 스스로 사라짐", model.bubbleText == nil)
            })
        ]
    }

    private func runStep(_ index: Int) {
        guard index < steps.count else { finish(); return }
        let step = steps[index]
        step.setup()
        // SwiftUI 가 다시 그릴 시간을 준 뒤 캡처한다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.snapshot(name: step.name)
            self.runStep(index + 1)
        }
    }

    /// 화면 녹화 권한 없이 창 내용을 그대로 PNG 로 저장한다.
    private func snapshot(name: String) {
        let view = controller.testContentView
        view.displayIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }

    private func finish() {
        let failed = results.filter { !$0.passed }
        print("────────────────────────────────────────")
        print("점검 \(results.count)개 · 실패 \(failed.count)개")
        print(failed.isEmpty ? "모두 통과 ✅" : "실패: \(failed.map(\.name).joined(separator: ", ")) ❌")
        print("창 모습 저장 위치: \(outputDirectory.path)")
        exit(failed.isEmpty ? 0 : 1)
    }
}
