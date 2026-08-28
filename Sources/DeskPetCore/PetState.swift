import Foundation

/// 캐릭터가 가질 수 있는 모든 상태.
public enum PetState: String, CaseIterable, Sendable {
    case idle
    case blink
    case lookLeft
    case lookRight
    case adjustGlasses
    case typingSlow
    case typingFast
    case drinkCoffee
    case sleepy
    case surprised
    case sulking

    /// 커서를 따라 눈동자를 움직여도 자연스러운 상태인지.
    public var followsCursor: Bool {
        switch self {
        case .idle, .blink, .lookLeft, .lookRight, .typingSlow, .typingFast, .adjustGlasses:
            return true
        case .drinkCoffee, .sleepy, .surprised, .sulking:
            return false
        }
    }

    /// 특수 동작(한 번에 하나만 실행하고 끝나면 idle 로 복귀).
    public var isOneShot: Bool {
        switch self {
        case .idle, .typingSlow, .typingFast, .lookLeft, .lookRight: return false
        case .blink, .adjustGlasses, .drinkCoffee, .sleepy, .surprised, .sulking: return true
        }
    }
}
