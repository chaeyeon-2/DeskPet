import AppKit
import SwiftUI
import DeskPetCore

/// 창의 위치/크기/애니메이션 루프를 관리한다.
final class PetWindowController {

    let model: PetViewModel
    private let panel: PetPanel
    private let contentView = PetContentView()
    private var hostingView: NSHostingView<PetView>
    private var timer: Timer?
    private let prefs: Preferences
    private let sound: SoundPlayer

    private(set) var isVisible = false

    /// 자체 점검(--selftest)에서만 쓰는 접근자.
    var testWindow: NSWindow { panel }
    var testContentView: PetContentView { contentView }
    var testHeadCenter: CGPoint { headCenterOnScreen() }
    func testMove(by delta: CGSize) { moveBy(delta) }
    func testSetOrigin(_ origin: CGPoint) { panel.setFrameOrigin(origin) }
    func testStopAnimationTimer() { stopTimer() }

    init(prefs: Preferences, sound: SoundPlayer) {
        self.prefs = prefs
        self.sound = sound
        self.model = PetViewModel(size: prefs.size)
        self.panel = PetPanel(size: model.windowSize)
        self.hostingView = NSHostingView(rootView: PetView(model: model))

        contentView.frame = CGRect(origin: .zero, size: model.windowSize)
        contentView.autoresizingMask = [.width, .height]
        hostingView.frame = contentView.bounds
        hostingView.autoresizingMask = [.width, .height]
        contentView.addSubview(hostingView)
        panel.contentView = contentView

        contentView.isOpaquePixel = { [weak self] x, y in
            self?.model.isOpaquePixel(canvasX: x, canvasY: y) ?? false
        }
        contentView.onDrag = { [weak self] delta in self?.moveBy(delta) }
        contentView.onDragEnd = { [weak self] in self?.savePosition() }
        contentView.onClick = { [weak self] onHead in
            guard let self else { return }
            self.model.registerClick(onHead: onHead, at: ProcessInfo.processInfo.systemUptime)
            self.sound.playPoke()
        }

        applyLayout()
        restorePosition()

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    // MARK: - 표시

    func setVisible(_ visible: Bool) {
        isVisible = visible
        if visible {
            panel.orderFrontRegardless()
            startTimer()
        } else {
            stopTimer()
            panel.orderOut(nil)
        }
    }

    func applySize(_ size: PetSize) {
        model.size = size
        applyLayout()
        clampIntoScreens()
        savePosition()
    }

    private func applyLayout() {
        let windowSize = model.windowSize
        var frame = panel.frame
        // 바닥 중앙을 기준으로 크기를 바꾼다.
        let anchorX = frame.midX
        let anchorY = frame.minY
        frame.size = windowSize
        frame.origin = CGPoint(x: anchorX - windowSize.width / 2, y: anchorY)
        panel.setFrame(frame, display: true)

        contentView.frame = CGRect(origin: .zero, size: windowSize)
        hostingView.frame = contentView.bounds
        let sprite = model.spriteSize
        contentView.spriteFrame = CGRect(x: (windowSize.width - sprite.width) / 2, y: 0,
                                         width: sprite.width, height: sprite.height)
        contentView.pixelScale = CGFloat(model.size.pixelScale)
    }

    // MARK: - 위치

    private func moveBy(_ delta: CGSize) {
        var origin = panel.frame.origin
        origin.x += delta.width
        origin.y += delta.height
        panel.setFrameOrigin(origin)
    }

    private func visibleFrames() -> [CGRect] {
        NSScreen.screens.map { $0.visibleFrame }
    }

    func clampIntoScreens() {
        let clamped = ScreenPlacement.clamp(frame: panel.frame, into: visibleFrames())
        if clamped != panel.frame { panel.setFrame(clamped, display: true) }
    }

    private func restorePosition() {
        let size = model.windowSize
        let frames = visibleFrames()
        let origin: CGPoint
        if let saved = prefs.savedOrigin {
            origin = saved
        } else if let main = NSScreen.main?.visibleFrame ?? frames.first {
            origin = ScreenPlacement.defaultOrigin(size: size, in: main)
        } else {
            origin = .zero
        }
        panel.setFrame(CGRect(origin: origin, size: size), display: false)
        clampIntoScreens()
    }

    func savePosition() {
        clampIntoScreens()
        prefs.savedOrigin = panel.frame.origin
    }

    func resetPosition() {
        guard let main = NSScreen.main?.visibleFrame else { return }
        let origin = ScreenPlacement.defaultOrigin(size: model.windowSize, in: main)
        panel.setFrameOrigin(origin)
        savePosition()
    }

    @objc private func screensChanged() {
        // 해상도나 Dock 이 바뀌어도 캐릭터가 화면 밖으로 나가지 않게 보정한다.
        clampIntoScreens()
        savePosition()
    }

    // MARK: - 애니메이션 루프

    private func startTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = 0.01
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        model.tick(now: now, headCenter: headCenterOnScreen(), cursor: CursorTracker.location)
    }

    private func headCenterOnScreen() -> CGPoint {
        let scale = CGFloat(model.size.pixelScale)
        let sprite = contentView.spriteFrame
        let origin = panel.frame.origin
        return CGPoint(x: origin.x + sprite.minX + (CGFloat(CharacterSprite.headCenterXValue) + 0.5) * scale,
                       y: origin.y + sprite.maxY - (CGFloat(CharacterSprite.headCenterYValue) + 0.5) * scale)
    }

    func registerKeystroke() {
        model.registerKeystroke(at: ProcessInfo.processInfo.systemUptime)
        sound.playKeyClick()
    }

    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
}
