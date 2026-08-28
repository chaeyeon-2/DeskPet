import Foundation

/// 키 입력 "사실"만 다루는 추적기.
/// 어떤 키가 눌렸는지, 어떤 문자가 입력됐는지는 절대 전달받지 않고 저장하지도 않는다.
/// 오직 "키가 눌린 시각"만 사용한다.
public struct TypingTracker: Sendable, Equatable {

    public struct Tuning: Sendable, Equatable {
        public var idleTimeout: TimeInterval = 1.5   // 이 시간 이상 멈추면 대기 상태로
        public var rateWindow: TimeInterval = 1.2    // 타속 계산 구간
        public var fastThreshold: Double = 4.0       // 초당 키 수가 이 값 이상이면 빠른 타이핑
        public init() {}
    }

    public var tuning = Tuning()
    private var timestamps: [TimeInterval] = []
    public private(set) var lastKeyTime: TimeInterval?

    public init(tuning: Tuning = Tuning()) { self.tuning = tuning }

    /// 키가 눌렸다는 사실만 기록한다.
    public mutating func registerKeystroke(at time: TimeInterval) {
        lastKeyTime = max(lastKeyTime ?? time, time)
        timestamps.append(time)
        prune(before: time - tuning.rateWindow)
    }

    private mutating func prune(before cutoff: TimeInterval) {
        if timestamps.count > 64 || (timestamps.first ?? .greatestFiniteMagnitude) < cutoff {
            timestamps.removeAll { $0 < cutoff }
        }
    }

    public func secondsSinceLastKey(at now: TimeInterval) -> TimeInterval? {
        lastKeyTime.map { max(0, now - $0) }
    }

    public func isTyping(at now: TimeInterval) -> Bool {
        guard let gap = secondsSinceLastKey(at: now) else { return false }
        return gap < tuning.idleTimeout
    }

    public func keysPerSecond(at now: TimeInterval) -> Double {
        let cutoff = now - tuning.rateWindow
        let count = timestamps.filter { $0 >= cutoff }.count
        return Double(count) / tuning.rateWindow
    }

    /// 타이핑 중이면 해당 상태, 아니면 nil.
    public func typingState(at now: TimeInterval) -> PetState? {
        guard isTyping(at: now) else { return nil }
        return keysPerSecond(at: now) >= tuning.fastThreshold ? .typingFast : .typingSlow
    }

    public mutating func reset() {
        timestamps.removeAll()
        lastKeyTime = nil
    }
}
