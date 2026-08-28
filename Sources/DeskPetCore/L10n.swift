import Foundation

/// 앱에서 쓸 언어.
public enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case korean
    case english

    public var title: String {
        switch self {
        case .system: return L10n.t("시스템 설정 따름", "Match System")
        case .korean: return "한국어"
        case .english: return "English"
        }
    }
}

/// 아주 작은 다국어 헬퍼.
///
/// `.lproj` 리소스 번들 대신 코드 안에 문자열 쌍을 두는 방식을 쓴다.
/// 이 앱은 `.app` 번들을 스크립트로 직접 조립하기 때문에, 리소스가 없는 편이
/// 빌드가 단순하고 깨질 일이 없다. 문자열 수도 많지 않다.
public enum L10n {

    nonisolated(unsafe) private static var preference: AppLanguage = .system

    /// 사용자가 메뉴에서 고른 언어를 반영한다.
    public static func setLanguage(_ language: AppLanguage) {
        preference = language
    }

    public static var language: AppLanguage { preference }

    /// 지금 한국어로 보여 줘야 하는지.
    public static var isKorean: Bool {
        switch preference {
        case .korean: return true
        case .english: return false
        case .system: return systemPrefersKorean
        }
    }

    /// 시스템 언어가 한국어인지 (테스트에서도 참조).
    public static var systemPrefersKorean: Bool {
        guard let first = Locale.preferredLanguages.first else { return false }
        return first.hasPrefix("ko")
    }

    /// 한국어 / 영어 문자열 중 하나를 고른다.
    public static func t(_ korean: String, _ english: String) -> String {
        isKorean ? korean : english
    }
}
