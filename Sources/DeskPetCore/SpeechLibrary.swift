import Foundation

// ─────────────────────────────────────────────────────────────
//  말풍선 문구와 표시 간격은 전부 이 파일에서만 고치면 된다.
// ─────────────────────────────────────────────────────────────

public struct SpeechLine: Sendable, Equatable, Identifiable {
    public let id: String
    public let text: String
    /// 뽑힐 가중치. 클수록 자주, 작을수록 드물게 나온다.
    public let weight: Double
    /// 이 시각(0...23)에만 나오는 문구. nil 이면 하루 종일 나온다.
    /// 예) 점심 문구는 [11, 12, 13]
    public let hours: [Int]?

    public init(id: String, text: String, weight: Double = 1, hours: [Int]? = nil) {
        self.id = id
        self.text = text
        self.weight = weight
        self.hours = hours
    }

    /// 지금 시각에 나올 수 있는 문구인지.
    public func isAllowed(hour: Int) -> Bool {
        guard let hours else { return true }
        return hours.contains(hour)
    }
}

public struct SpeechTuning: Sendable, Equatable {
    /// 입력이 없는 상태가 이 시간(초)을 넘겨야 말풍선 후보가 된다. (3분)
    public var idleThreshold: TimeInterval = 180
    /// 말풍선을 띄울지 검사하는 주기(초).
    public var checkInterval: TimeInterval = 20
    /// 검사할 때마다 실제로 띄울 확률. (낮게 유지 = 잔소리처럼 느껴지지 않게)
    public var chancePerCheck: Double = 0.18
    /// 같은 문구를 다시 쓰기까지의 최소 간격(초). (15분)
    public var perLineCooldown: TimeInterval = 900
    /// 어떤 문구든 연달아 나오지 않도록 하는 최소 간격(초).
    public var globalCooldown: TimeInterval = 120
    /// 말풍선이 떠 있는 시간(초) 범위.
    public var minDuration: TimeInterval = 3
    public var maxDuration: TimeInterval = 5
    /// 늦은 밤 판정 (23시 ~ 새벽 5시).
    public var lateNightStartHour: Int = 23
    public var lateNightEndHour: Int = 5

    public init() {}

    public func isLateNight(hour: Int) -> Bool {
        hour >= lateNightStartHour || hour < lateNightEndHour
    }
}

/// 말풍선이 얼마나 자주 나올지. 메뉴 막대에서 바꿀 수 있다.
public enum SpeechFrequency: String, CaseIterable, Sendable {
    case rare, normal, often

    public var title: String {
        switch self {
        case .rare: return "드물게"
        case .normal: return "보통"
        case .often: return "자주"
        }
    }

    public var tuning: SpeechTuning {
        var t = SpeechTuning()
        switch self {
        case .rare:      // 잔소리처럼 느껴지지 않는 아주 조용한 설정
            t.idleThreshold = 180
            t.checkInterval = 20
            t.chancePerCheck = 0.18
            t.perLineCooldown = 900
            t.globalCooldown = 120
        case .normal:    // 기본값
            t.idleThreshold = 45
            t.checkInterval = 12
            t.chancePerCheck = 0.40
            t.perLineCooldown = 420
            t.globalCooldown = 50
        case .often:     // 수다스러운 설정
            t.idleThreshold = 12
            t.checkInterval = 8
            t.chancePerCheck = 0.65
            t.perLineCooldown = 180
            t.globalCooldown = 20
        }
        return t
    }
}

public enum SpeechLibrary {
    /// 말풍선 후보 문구. 여기만 고치면 앱 전체에 반영된다.
    public static let lines: [SpeechLine] = [
        SpeechLine(id: "hmm",        text: "흠…",                weight: 3),
        SpeechLine(id: "focusing",   text: "집중 중?",            weight: 3),
        SpeechLine(id: "glasses",    text: "안경에 다 비치는데…",   weight: 2),
        SpeechLine(id: "rest",       text: "잠깐 쉬어도 돼",       weight: 3),
        SpeechLine(id: "pretend",    text: "나도 일하는 척하는 중", weight: 2),
        SpeechLine(id: "quiet",      text: "키보드 조용한데?",     weight: 3),
        SpeechLine(id: "coffee",     text: "커피 마실래?",         weight: 2),
        SpeechLine(id: "tough",      text: "오늘도 쉽지 않네",      weight: 2),
        SpeechLine(id: "chat",       text: "yup! happy to chat!", weight: 2),
        SpeechLine(id: "focus",      text: "집중해!",             weight: 2),
        SpeechLine(id: "distracted", text: "딴짓하니?",           weight: 0.4),   // 가장 드물게

        // 시간대에 맞춰 나오는 문구
        SpeechLine(id: "lunch",      text: "오늘 점심은?",         weight: 4, hours: lunchHours),
        SpeechLine(id: "dinner",     text: "오늘 저녁은?",         weight: 4, hours: dinnerHours),
        SpeechLine(id: "lateNight",  text: "아직도 안 자?",        weight: 3, hours: lateNightHours)
    ]

    /// 시간대 정의 — 여기만 고치면 문구가 나오는 시간이 바뀐다.
    public static let lunchHours = [11, 12, 13]
    public static let dinnerHours = [17, 18, 19]
    public static let lateNightHours = [23, 0, 1, 2, 3, 4]

    public static let tuning = SpeechTuning()

    /// 캐릭터를 클릭했을 때 가끔 튀어나오는 짧은 대꾸.
    public static let pokeLines: [SpeechLine] = [
        SpeechLine(id: "poke.why",    text: "왜?",            weight: 3),
        SpeechLine(id: "poke.hi",     text: "yup! happy to chat!", weight: 2),
        SpeechLine(id: "poke.itchy",  text: "간지러워",        weight: 2),
        SpeechLine(id: "poke.oh",     text: "앗",              weight: 3),
        SpeechLine(id: "poke.busy",   text: "집중 중인데…",     weight: 2),
        SpeechLine(id: "poke.again",  text: "또?",             weight: 2),
        SpeechLine(id: "poke.stop",   text: "그만 눌러…",       weight: 1)
    ]

    /// 클릭 대꾸가 연달아 나오지 않게 하는 최소 간격(초)과 표시 시간.
    public static let pokeCooldown: TimeInterval = 5
    public static let pokeChance: Double = 0.65
    public static let pokeDuration: TimeInterval = 2.4
}
