import Foundation

public enum MouthStyle: Sendable, Hashable {
    case neutral      // 무표정 한 줄
    case smile        // 살짝 웃음
    case open         // 놀람(동그란 입)
    case wavy         // 삐짐(물결)
    case sip          // 컵에 입 대기
    case yawn         // 하품
}

public enum CupPose: Sendable, Hashable {
    case hidden
    case onDesk
    case raised
    case atMouth
}

/// 캐릭터가 입는 옷.
public enum Outfit: String, CaseIterable, Sendable, Hashable {
    case checkShirt
    case orangePuffer
    case kixlabTee
    case lgUniform

    public var title: String {
        switch self {
        case .checkShirt: return L10n.t("파란 체크 셔츠", "Blue Check Shirt")
        case .orangePuffer: return L10n.t("주황 패딩", "Orange Puffer")
        case .kixlabTee: return L10n.t("I ♥ KIXLAB 티셔츠", "I ♥ KIXLAB Tee")
        case .lgUniform: return L10n.t("LG 트윈스 유니폼", "LG Twins Jersey")
        }
    }
}

public struct PosePoint: Sendable, Hashable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

/// 한 프레임의 캐릭터 자세. 모든 애니메이션은 이 값만 바꿔서 만든다.
public struct Pose: Sendable, Hashable {
    public var outfit: Outfit = .checkShirt
    public var eyeOpen: Double = 1.0        // 0 = 감음, 1 = 완전히 뜸
    public var gazeX: Int = 0               // 눈동자 좌우 (-2...2)
    public var gazeY: Int = 0               // 눈동자 상하 (-1...1)
    public var headShear: Double = 0        // 고개 갸웃 (양수 = 오른쪽으로)
    public var headOffsetY: Int = 0         // 숨쉬기 상하 이동
    public var bodyOffsetY: Int = 0
    public var browRaise: Int = 0           // 눈썹 올림 (-1...2)
    public var glassesOffsetX: Int = 0
    public var glassesOffsetY: Int = 0
    public var glassesTilt: Int = 0         // 안경 삐뚤어짐
    public var glassesGlare: Bool = true
    public var mouth: MouthStyle = .neutral
    public var blush: Bool = false
    public var leftHandLift: Int = 0        // 타이핑 손 들림 (0...2)
    public var rightHandLift: Int = 0
    public var handsOnKeyboard: Bool = false
    public var showDesk: Bool = false
    public var keyboardPress: Int = 0       // 키보드가 눌린 정도 (0/1)
    public var pressedKey: Int? = nil       // 눌린 키 인덱스 (0...9)
    public var cup: CupPose = .hidden
    public var sleepZ: Int = 0              // 0 = 없음, 1...3 = zzz 단계
    public var steam: Bool = false
    public var sweat: Bool = false          // 삐짐/당황 표시
    public var leftHandOverride: PosePoint? = nil   // 특수 동작용 손 위치
    public var rightHandOverride: PosePoint? = nil

    public init() {}
}
