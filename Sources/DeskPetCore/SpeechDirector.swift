import Foundation

public struct SpeechBubble: Sendable, Equatable {
    public let lineID: String
    public let text: String
    public let duration: TimeInterval
}

/// 말풍선을 언제/무엇을 띄울지 결정한다. 시간과 난수를 주입받아 테스트할 수 있다.
public struct SpeechDirector: Sendable {

    public var tuning: SpeechTuning
    public var lines: [SpeechLine]
    private var lastShownByLine: [String: TimeInterval] = [:]
    private var lastShownAt: TimeInterval?
    private var nextCheckAt: TimeInterval?
    private var lastPokeAt: TimeInterval?
    private var lastPokeID: String?

    public init(lines: [SpeechLine] = SpeechLibrary.lines, tuning: SpeechTuning = SpeechLibrary.tuning) {
        self.lines = lines
        self.tuning = tuning
    }

    public mutating func reset() {
        lastShownByLine.removeAll()
        lastShownAt = nil
        nextCheckAt = nil
        lastPokeAt = nil
        lastPokeID = nil
    }

    /// 캐릭터를 클릭했을 때의 짧은 대꾸. 너무 자주 뜨지 않게 간격을 둔다.
    public mutating func poke(now: TimeInterval, random: () -> Double) -> SpeechBubble? {
        if let last = lastPokeAt, now - last < SpeechLibrary.pokeCooldown { return nil }
        guard random() < SpeechLibrary.pokeChance else { return nil }
        let candidates = SpeechLibrary.pokeLines.filter { $0.id != lastPokeID }
        guard !candidates.isEmpty else { return nil }
        let chosen = weightedPick(candidates, random: random)
        lastPokeAt = now
        lastPokeID = chosen.id
        lastShownAt = now
        return SpeechBubble(lineID: chosen.id, text: chosen.text, duration: SpeechLibrary.pokeDuration)
    }

    private func weightedPick(_ candidates: [SpeechLine], random: () -> Double) -> SpeechLine {
        let total = candidates.reduce(0) { $0 + $1.weight }
        var pick = random() * total
        for line in candidates {
            pick -= line.weight
            if pick <= 0 { return line }
        }
        return candidates[candidates.count - 1]
    }

    /// 입력이 있을 때마다 호출하면 "쉬는 중" 타이머가 리셋된다.
    public mutating func noteActivity() {
        nextCheckAt = nil
    }

    /// - Parameters:
    ///   - now: 현재 시각(단조 증가 초)
    ///   - idleSeconds: 마지막 키 입력 이후 지난 시간
    ///   - hour: 현재 시각의 "시" (0...23)
    ///   - random: 0...1 난수 생성기 (테스트에서 고정 가능)
    public mutating func evaluate(now: TimeInterval,
                                  idleSeconds: TimeInterval,
                                  hour: Int,
                                  random: () -> Double) -> SpeechBubble? {
        guard idleSeconds >= tuning.idleThreshold else {
            nextCheckAt = nil
            return nil
        }
        // 검사 주기가 되지 않았으면 아무것도 하지 않는다.
        if let next = nextCheckAt {
            guard now >= next else { return nil }
        } else {
            nextCheckAt = now + tuning.checkInterval
            return nil
        }
        nextCheckAt = now + tuning.checkInterval

        if let last = lastShownAt, now - last < tuning.globalCooldown { return nil }
        guard random() < tuning.chancePerCheck else { return nil }

        let candidates = lines.filter { line in
            if !line.isAllowed(hour: hour) { return false }
            if let shown = lastShownByLine[line.id], now - shown < tuning.perLineCooldown { return false }
            return true
        }
        guard !candidates.isEmpty else { return nil }

        let chosen = weightedPick(candidates, random: random)

        lastShownByLine[chosen.id] = now
        lastShownAt = now
        let span = max(0, tuning.maxDuration - tuning.minDuration)
        let duration = tuning.minDuration + random() * span
        return SpeechBubble(lineID: chosen.id, text: chosen.text, duration: duration)
    }
}
