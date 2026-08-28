import AppKit
import SwiftUI
import DeskPetCore

/// 화면에 그릴 내용을 들고 있는 모델. 타이머가 tick 을 호출한다.
final class PetViewModel: ObservableObject {

    @Published private(set) var image: NSImage
    @Published private(set) var bubbleText: String?

    let brain: PetBrain
    private var speech = SpeechDirector()
    private(set) var currentCanvas: PixelCanvas
    private(set) var currentState: PetState = .idle
    private(set) var currentPose = Pose()

    var size: PetSize {
        didSet {
            guard size != oldValue else { return }
            lastPose = nil
            objectWillChange.send()
        }
    }
    /// 캐릭터가 입는 옷 (메뉴 막대에서 변경).
    var outfit: Outfit = .checkShirt {
        didSet {
            guard outfit != oldValue else { return }
            lastPose = nil          // 다음 프레임에서 다시 그리게 한다
        }
    }
    var bubblesEnabled = true {
        didSet { if !bubblesEnabled { bubbleText = nil; bubbleEndsAt = nil } }
    }
    /// 말풍선 빈도 (메뉴 막대에서 변경).
    var bubbleFrequency: SpeechFrequency = .normal {
        didSet { speech.tuning = bubbleFrequency.tuning }
    }

    private var lastPose: Pose?
    private var bubbleEndsAt: TimeInterval?
    private let startedAt: TimeInterval

    /// 말풍선 영역 높이(pt). 창 크기 계산에 쓰인다.
    let bubbleAreaHeight: CGFloat = 60

    var spriteSize: CGSize { size.spriteSize }
    var windowSize: CGSize {
        CGSize(width: max(spriteSize.width, 220), height: spriteSize.height + bubbleAreaHeight)
    }

    init(size: PetSize, now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        self.size = size
        self.startedAt = now
        self.brain = PetBrain(now: now)
        let pose = Pose()
        self.currentCanvas = CharacterSprite.render(pose)
        self.image = SpriteImageProvider.image(for: currentCanvas, size: size.spriteSize)
    }

    func registerKeystroke(at now: TimeInterval) {
        brain.registerKeystroke(at: now)
        speech.noteActivity()
    }

    func registerClick(onHead: Bool, at now: TimeInterval) {
        brain.registerClick(onHead: onHead, at: now)
        // 눌렀을 때 바로 반응이 오도록 가끔 짧게 대꾸한다.
        guard bubblesEnabled else { return }
        if let poke = speech.poke(now: now, random: { Double.random(in: 0..<1) }) {
            bubbleText = poke.text
            bubbleEndsAt = now + poke.duration
        }
    }

    /// - Parameters:
    ///   - headCenter: 화면 좌표 기준 캐릭터 머리 중심
    ///   - cursor: 화면 좌표 기준 커서 위치
    func tick(now: TimeInterval, headCenter: CGPoint, cursor: CGPoint) {
        let gaze = GazeSolver.solve(headCenter: headCenter, cursor: cursor)
        let render = brain.update(now: now, gaze: gaze)
        var pose = render.pose
        pose.outfit = outfit
        currentState = render.state
        currentPose = pose

        if lastPose != pose {
            lastPose = pose
            currentCanvas = SpriteImageProvider.canvas(for: pose)
            image = SpriteImageProvider.image(for: pose,
                                              state: render.state,
                                              frame: render.frameIndex,
                                              size: spriteSize)
        }

        updateBubble(now: now)
    }

    private func updateBubble(now: TimeInterval) {
        guard bubblesEnabled else { return }
        if let end = bubbleEndsAt {
            if now >= end {
                bubbleEndsAt = nil
                bubbleText = nil
            }
            return
        }
        let idle = brain.secondsSinceLastKey(at: now) ?? (now - startedAt)
        let hour = Calendar.current.component(.hour, from: Date())
        if let bubble = speech.evaluate(now: now, idleSeconds: idle, hour: hour,
                                        random: { Double.random(in: 0..<1) }) {
            bubbleText = bubble.text
            bubbleEndsAt = now + bubble.duration
        }
    }

    /// 안내 문구를 직접 띄운다(권한 안내, 자체 점검 등).
    func showHint(_ text: String, seconds: TimeInterval, now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard bubblesEnabled else { return }
        bubbleText = text
        bubbleEndsAt = now + seconds
    }

    /// 캐릭터 그림 위(불투명 픽셀)인지 검사한다. 창의 나머지 영역은 클릭이 통과한다.
    func isOpaquePixel(canvasX: Int, canvasY: Int) -> Bool {
        currentCanvas.isOpaque(x: canvasX, y: canvasY)
    }
}
