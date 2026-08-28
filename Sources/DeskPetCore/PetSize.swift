import Foundation
import CoreGraphics

/// 메뉴에서 고르는 캐릭터 크기. 픽셀이 뭉개지지 않도록 정수 배율만 쓴다.
public enum PetSize: String, CaseIterable, Sendable {
    case small, medium, large

    public var pixelScale: Int {
        switch self {
        case .small: return 2    //  96pt
        case .medium: return 3   // 144pt  (기본)
        case .large: return 4    // 192pt
        }
    }

    public var title: String {
        switch self {
        case .small: return L10n.t("작게", "Small")
        case .medium: return L10n.t("보통", "Medium")
        case .large: return L10n.t("크게", "Large")
        }
    }

    public var spriteSize: CGSize {
        CGSize(width: CharacterSprite.canvasWidth * pixelScale,
               height: CharacterSprite.canvasHeight * pixelScale)
    }
}
