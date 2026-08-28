import Foundation

public struct RenderState: Sendable, Equatable {
    public let state: PetState
    public let pose: Pose
    public let animationTime: TimeInterval
    public let frameIndex: Int
}

public struct BrainTuning: Sendable, Equatable {
    /// 눈 깜빡임 간격(초).
    public var blinkIntervalMin: Double = 3
    public var blinkIntervalMax: Double = 7
    /// 특수 동작(안경 고쳐 쓰기, 커피, 졸기, 고개 갸웃) 사이 간격(초).
    public var specialIntervalMin: Double = 14
    public var specialIntervalMax: Double = 34
    /// 특수 동작 사이 최소 휴지 시간(초) — 한 번에 하나씩, 정신없지 않게.
    public var minSpecialGap: Double = 9
    /// 이만큼 입력이 없어야 졸기 시작한다.
    public var sleepyIdleThreshold: Double = 90
    /// 머리를 이 시간 안에 이 횟수만큼 클릭하면 삐진다.
    public var headClickWindow: Double = 1.8
    public var headClickCount: Int = 3
    /// 고개 갸웃 유지 시간.
    public var tiltDuration: Double = 1.8
    public init() {}
}

/// 캐릭터 상태 머신. 시간과 난수를 주입받아 테스트할 수 있다.
public final class PetBrain {

    public private(set) var state: PetState = .idle
    public private(set) var typing = TypingTracker()
    public var tuning = BrainTuning()

    private var animation: SpriteAnimation
    private var stateStart: TimeInterval
    private var nextBlinkAt: TimeInterval
    private var nextSpecialAt: TimeInterval
    private var lastSpecialAt: TimeInterval
    private var headClicks: [TimeInterval] = []
    private var forcedLook: (state: PetState, until: TimeInterval)?
    private let random: () -> Double

    public init(now: TimeInterval, random: @escaping () -> Double = { Double.random(in: 0..<1) }) {
        self.random = random
        self.stateStart = now
        self.animation = AnimationLibrary.animation(for: .idle)
        self.nextBlinkAt = now + 3
        self.nextSpecialAt = now + 12
        self.lastSpecialAt = now
    }

    // MARK: - 입력

    /// 키가 눌렸다는 "사실"만 전달받는다. 어떤 키였는지는 알지도, 저장하지도 않는다.
    public func registerKeystroke(at now: TimeInterval) {
        typing.registerKeystroke(at: now)
    }

    public func registerClick(onHead: Bool, at now: TimeInterval) {
        if onHead {
            headClicks.removeAll { now - $0 > tuning.headClickWindow }
            headClicks.append(now)
            if headClicks.count >= tuning.headClickCount {
                headClicks.removeAll()
                transition(to: .sulking, at: now)
                return
            }
        }
        if state == .sulking, !isAnimationFinished(at: now) { return }
        transition(to: .surprised, at: now)
    }

    public func secondsSinceLastKey(at now: TimeInterval) -> TimeInterval? {
        typing.secondsSinceLastKey(at: now)
    }

    // MARK: - 매 프레임 갱신

    public func update(now: TimeInterval, gaze: Gaze) -> RenderState {
        let finished = isAnimationFinished(at: now)
        let typingState = typing.typingState(at: now)
        var next: PetState?

        if state.isOneShot && !finished {
            // 진행 중인 일회성 동작은 끝까지 보여 준다. 단, 타이핑은 즉시 반응한다.
            if typingState != nil {
                switch state {
                case .sleepy: next = .surprised          // 졸다가 화들짝 깨기
                case .blink, .adjustGlasses, .drinkCoffee: next = typingState
                default: break                            // surprised / sulking 은 끝까지
                }
            }
        } else if state == .sleepy && finished {
            next = .surprised                             // 잠에서 깨어나는 연출
        } else if let t = typingState {
            next = t
        } else if now >= nextBlinkAt {
            next = .blink
        } else if now >= nextSpecialAt, now - lastSpecialAt >= tuning.minSpecialGap {
            next = pickSpecial(now: now)
        } else if let forced = forcedLook, now < forced.until {
            next = forced.state
        } else {
            forcedLook = nil
            if gaze.isNear && gaze.horizontal < 0 { next = .lookLeft }
            else if gaze.isNear && gaze.horizontal > 0 { next = .lookRight }
            else { next = .idle }
        }

        if let next, next != state { transition(to: next, at: now) }
        return render(now: now, gaze: gaze)
    }

    // MARK: - 내부

    private func isAnimationFinished(at now: TimeInterval) -> Bool {
        !animation.loops && (now - stateStart) >= animation.totalDuration
    }

    private func pickSpecial(now: TimeInterval) -> PetState {
        var options: [(PetState, Double)] = [
            (.adjustGlasses, 3),
            (.drinkCoffee, 2),
            (.lookLeft, 1.5),      // 고개 갸웃
            (.lookRight, 1.5)
        ]
        let idle = typing.secondsSinceLastKey(at: now) ?? .greatestFiniteMagnitude
        if idle >= tuning.sleepyIdleThreshold { options.append((.sleepy, 2)) }

        let total = options.reduce(0) { $0 + $1.1 }
        var pick = random() * total
        var chosen = options[options.count - 1].0
        for (s, w) in options {
            pick -= w
            if pick <= 0 { chosen = s; break }
        }
        lastSpecialAt = now
        nextSpecialAt = now + tuning.specialIntervalMin
            + random() * (tuning.specialIntervalMax - tuning.specialIntervalMin)
        if chosen == .lookLeft || chosen == .lookRight {
            forcedLook = (chosen, now + tuning.tiltDuration)
        }
        return chosen
    }

    private func transition(to newState: PetState, at now: TimeInterval) {
        state = newState
        stateStart = now
        animation = AnimationLibrary.animation(for: newState)
        if newState == .blink {
            nextBlinkAt = now + animation.totalDuration + tuning.blinkIntervalMin
                + random() * (tuning.blinkIntervalMax - tuning.blinkIntervalMin)
        }
        if newState.isOneShot && newState != .blink {
            lastSpecialAt = now
            if nextSpecialAt < now {
                nextSpecialAt = now + tuning.specialIntervalMin
                    + random() * (tuning.specialIntervalMax - tuning.specialIntervalMin)
            }
        }
    }

    private func render(now: TimeInterval, gaze: Gaze) -> RenderState {
        let t = now - stateStart
        let index = animation.frameIndex(at: t)
        var pose = animation.frames[index].pose
        if state.followsCursor && gaze.isNear {
            pose.gazeX = gaze.x
            pose.gazeY = gaze.y
            switch state {
            case .idle, .blink:
                pose.headShear += Double(gaze.x) * 0.018   // 커서 쪽으로 살짝 고개
            default:
                break
            }
        }
        return RenderState(state: state, pose: pose, animationTime: t, frameIndex: index)
    }
}
