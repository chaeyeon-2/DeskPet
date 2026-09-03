import Foundation

public struct AnimationFrame: Sendable, Equatable {
    public let pose: Pose
    public let duration: TimeInterval
    public init(_ pose: Pose, _ duration: TimeInterval) {
        self.pose = pose
        self.duration = duration
    }
}

public struct SpriteAnimation: Sendable, Equatable {
    public let frames: [AnimationFrame]
    public let loops: Bool

    public var totalDuration: TimeInterval { frames.reduce(0) { $0 + $1.duration } }

    public init(frames: [AnimationFrame], loops: Bool) {
        self.frames = frames
        self.loops = loops
    }

    /// 애니메이션 시작 후 t초 시점의 프레임 인덱스.
    public func frameIndex(at t: TimeInterval) -> Int {
        guard !frames.isEmpty else { return 0 }
        let total = totalDuration
        guard total > 0 else { return 0 }
        var time = t
        if loops { time = t.truncatingRemainder(dividingBy: total) }
        else if t >= total { return frames.count - 1 }
        var acc: TimeInterval = 0
        for (i, f) in frames.enumerated() {
            acc += f.duration
            if time < acc { return i }
        }
        return frames.count - 1
    }

    public func pose(at t: TimeInterval) -> Pose { frames[frameIndex(at: t)].pose }
}

/// 상태별 애니메이션 정의. 프레임 자체는 Pose 파라미터로만 표현된다.
public enum AnimationLibrary {

    public static func animation(for state: PetState, typingSpeed: Double = 0) -> SpriteAnimation {
        switch state {
        case .idle:          return idle()
        case .blink:         return blink()
        case .lookLeft:      return look(dx: -2, shear: -0.05)
        case .lookRight:     return look(dx: 2, shear: 0.05)
        case .adjustGlasses: return adjustGlasses()
        case .typingSlow:    return typing(step: 0.17, fast: false)
        case .typingFast:    return typing(step: 0.075, fast: true)
        case .drinkCoffee:   return drinkCoffee()
        case .sleepy:        return sleepy()
        case .surprised:     return surprised()
        case .sulking:       return sulking()
        }
    }

    static func base() -> Pose {
        var p = Pose()
        p.mouth = .neutral
        return p
    }

    /// 편안하지만 처지지 않게 숨 쉬기.
    static func idle() -> SpriteAnimation {
        var a = base(); a.headOffsetY = 0; a.bodyOffsetY = 0
        var b = base(); b.headOffsetY = 1; b.bodyOffsetY = 1
        var c = base(); c.headOffsetY = 1; c.bodyOffsetY = 0
        return SpriteAnimation(frames: [
            AnimationFrame(a, 0.7), AnimationFrame(b, 0.55),
            AnimationFrame(c, 0.3), AnimationFrame(a, 0.65)
        ], loops: true)
    }

    static func blink() -> SpriteAnimation {
        var open = base()
        var half = base(); half.eyeOpen = 0.5
        var shut = base(); shut.eyeOpen = 0.0
        open.headOffsetY = 1; half.headOffsetY = 1; shut.headOffsetY = 1
        return SpriteAnimation(frames: [
            AnimationFrame(half, 0.05), AnimationFrame(shut, 0.09),
            AnimationFrame(half, 0.05), AnimationFrame(open, 0.05)
        ], loops: false)
    }

    static func look(dx: Int, shear: Double) -> SpriteAnimation {
        var p = base(); p.gazeX = dx; p.headShear = shear
        var q = p; q.headOffsetY = 1
        return SpriteAnimation(frames: [
            AnimationFrame(p, 0.9), AnimationFrame(q, 0.9)
        ], loops: true)
    }

    /// 안경 고쳐 쓰기: 오른손을 올려 안경을 살짝 밀어 올린다.
    static func adjustGlasses() -> SpriteAnimation {
        var p0 = base()
        var p1 = base(); p1.rightHandOverride = PosePoint(40, 30)
        var p2 = base(); p2.rightHandOverride = PosePoint(41, 21); p2.glassesOffsetY = 1; p2.eyeOpen = 0.6
        var p3 = base(); p3.rightHandOverride = PosePoint(41, 20); p3.glassesOffsetY = -1; p3.glassesGlare = true; p3.eyeOpen = 0.4
        var p4 = base(); p4.rightHandOverride = PosePoint(40, 30); p4.mouth = .smile
        p0.headOffsetY = 1
        return SpriteAnimation(frames: [
            AnimationFrame(p0, 0.12), AnimationFrame(p1, 0.14), AnimationFrame(p2, 0.30),
            AnimationFrame(p3, 0.22), AnimationFrame(p4, 0.16), AnimationFrame(p0, 0.20)
        ], loops: false)
    }

    /// 타자 치기: 양손이 번갈아 움직이고 키보드가 살짝 눌린다.
    static func typing(step: TimeInterval, fast: Bool) -> SpriteAnimation {
        func frame(left: Int, right: Int, press: Int, key: Int) -> Pose {
            var p = base()
            p.handsOnKeyboard = true
            p.showDesk = true
            p.leftHandLift = left
            p.rightHandLift = right
            p.keyboardPress = press
            p.pressedKey = key
            p.mouth = fast ? .smile : .neutral
            p.headOffsetY = press
            p.bodyOffsetY = press
            p.browRaise = fast ? 1 : 0
            return p
        }
        return SpriteAnimation(frames: [
            AnimationFrame(frame(left: 2, right: 0, press: 0, key: 3), step),
            AnimationFrame(frame(left: 0, right: 0, press: 1, key: 12), step),
            AnimationFrame(frame(left: 0, right: 2, press: 0, key: 7), step),
            AnimationFrame(frame(left: 0, right: 0, press: 1, key: 16), step)
        ], loops: true)
    }

    static func drinkCoffee() -> SpriteAnimation {
        var p0 = base(); p0.cup = .onDesk; p0.showDesk = true; p0.steam = true
        var p1 = base(); p1.cup = .raised; p1.showDesk = true; p1.steam = true; p1.eyeOpen = 0.7
        var p2 = base(); p2.cup = .atMouth; p2.showDesk = true; p2.steam = true; p2.mouth = .sip; p2.eyeOpen = 0.3; p2.headOffsetY = -1
        var p3 = p2; p3.headOffsetY = 1
        var p4 = base(); p4.cup = .raised; p4.showDesk = true; p4.mouth = .smile; p4.eyeOpen = 0.6
        var p5 = base(); p5.cup = .onDesk; p5.showDesk = true; p5.mouth = .smile
        return SpriteAnimation(frames: [
            AnimationFrame(p0, 0.35), AnimationFrame(p1, 0.30), AnimationFrame(p2, 0.55),
            AnimationFrame(p3, 0.55), AnimationFrame(p4, 0.35), AnimationFrame(p5, 0.60)
        ], loops: false)
    }

    /// 꾸벅꾸벅 졸기 (깨어나는 부분은 상태 머신이 surprised 로 이어 준다).
    static func sleepy() -> SpriteAnimation {
        func f(_ eye: Double, _ tilt: Double, _ z: Int, _ down: Int) -> Pose {
            var p = base()
            p.eyeOpen = eye
            p.headShear = tilt
            p.headOffsetY = down
            p.sleepZ = z
            p.browRaise = -1
            p.mouth = z >= 2 ? .yawn : .neutral
            return p
        }
        return SpriteAnimation(frames: [
            AnimationFrame(f(0.5, 0.03, 0, 0), 0.5),
            AnimationFrame(f(0.2, 0.08, 1, 1), 0.7),
            AnimationFrame(f(0.0, 0.12, 2, 2), 0.9),
            AnimationFrame(f(0.0, 0.14, 3, 2), 0.9),
            AnimationFrame(f(0.0, 0.12, 2, 2), 0.9)
        ], loops: false)
    }

    static func surprised() -> SpriteAnimation {
        var p0 = base()
        p0.eyeOpen = 1; p0.browRaise = 2; p0.mouth = .open
        p0.glassesTilt = 1; p0.glassesOffsetY = -1; p0.headOffsetY = -1; p0.blush = true
        var p1 = p0; p1.glassesTilt = 0; p1.glassesOffsetX = 1; p1.headOffsetY = 0
        var p2 = base(); p2.browRaise = 1; p2.mouth = .smile; p2.blush = true; p2.eyeOpen = 0.8
        return SpriteAnimation(frames: [
            AnimationFrame(p0, 0.28), AnimationFrame(p1, 0.24), AnimationFrame(p2, 0.35)
        ], loops: false)
    }

    static func sulking() -> SpriteAnimation {
        var p0 = base()
        p0.mouth = .wavy; p0.browRaise = -1; p0.eyeOpen = 0.45; p0.blush = true
        p0.headShear = -0.09; p0.gazeX = -2; p0.sweat = true
        var p1 = p0; p1.headShear = -0.11; p1.headOffsetY = 1
        var p2 = p0; p2.eyeOpen = 0.3
        return SpriteAnimation(frames: [
            AnimationFrame(p0, 0.5), AnimationFrame(p1, 0.5), AnimationFrame(p2, 0.5), AnimationFrame(p1, 0.5)
        ], loops: false)
    }
}
