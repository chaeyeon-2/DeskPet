import Foundation

/// 팔레트 색 하나. 0(clear)은 투명 픽셀을 뜻한다.
public enum PixelColor: UInt8, CaseIterable, Sendable {
    case clear = 0
    case outline          // 전체 외곽선
    case hair             // 검은 가르마 머리
    case hairHighlight    // 머릿결 하이라이트
    case skin
    case skinShade
    case skinLine         // 코/턱 선
    case brow             // 눈썹
    case glassFrame       // 사각 안경테
    case lens             // 안경 알
    case lensGlare        // 안경 반사
    case eyeWhite
    case pupil
    case mouth
    case shirt            // 파란 체크 셔츠 바탕
    case shirtCheck       // 체크 세로/가로 줄
    case shirtCross       // 줄이 겹치는 칸
    case collar           // 흰 카라
    case puffer           // 주황 패딩 바탕
    case pufferShade      // 패딩 음영
    case pufferSeam       // 패딩 누빔선
    case pufferHigh       // 패딩 하이라이트(부푼 느낌)
    case zipper           // 지퍼
    case tee              // 흰 티셔츠
    case teeShade         // 티셔츠 음영
    case teeInk           // 티셔츠 글자
    case pinstripe        // 야구 유니폼 세로 줄무늬
    case uniformBlack     // 유니폼 어깨 띠
    case uniformRed       // 유니폼 글자
    case deskLight
    case deskDark
    case keyBody
    case keyCap
    case keyShadow
    case cupBody
    case cupShade
    case cupHeart
    case blush
    case zzz
    case steam

    public var rgba: (UInt8, UInt8, UInt8, UInt8) {
        switch self {
        case .clear:         return (0, 0, 0, 0)
        case .outline:       return (0x2B, 0x24, 0x30, 0xFF)
        case .hair:          return (0x23, 0x1E, 0x28, 0xFF)
        case .hairHighlight: return (0x46, 0x3D, 0x50, 0xFF)
        case .skin:          return (0xF8, 0xD9, 0xB9, 0xFF)
        case .skinShade:     return (0xE3, 0xB9, 0x94, 0xFF)
        case .skinLine:      return (0xC7, 0x94, 0x70, 0xFF)
        case .brow:          return (0x2A, 0x22, 0x2C, 0xFF)
        case .glassFrame:    return (0x4A, 0x3A, 0x2C, 0xFF)
        case .lens:          return (0xDC, 0xEC, 0xF7, 0xFF)
        case .lensGlare:     return (0xFF, 0xFF, 0xFF, 0xFF)
        case .eyeWhite:      return (0xFF, 0xFF, 0xFF, 0xFF)
        case .pupil:         return (0x2B, 0x24, 0x30, 0xFF)
        case .mouth:         return (0xA5, 0x5B, 0x5B, 0xFF)
        case .shirt:         return (0x8F, 0xBE, 0xE8, 0xFF)
        case .shirtCheck:    return (0x5E, 0x92, 0xC6, 0xFF)
        case .shirtCross:    return (0x3C, 0x6C, 0xA0, 0xFF)
        case .collar:        return (0xF2, 0xF7, 0xFC, 0xFF)
        case .puffer:        return (0xF2, 0x8B, 0x3C, 0xFF)
        case .pufferShade:   return (0xD1, 0x6B, 0x22, 0xFF)
        case .pufferSeam:    return (0xA9, 0x50, 0x16, 0xFF)
        case .pufferHigh:    return (0xFF, 0xB4, 0x6E, 0xFF)
        case .zipper:        return (0xFA, 0xE7, 0xCC, 0xFF)
        case .tee:           return (0xF7, 0xF4, 0xEE, 0xFF)
        case .teeShade:      return (0xD5, 0xD1, 0xC8, 0xFF)
        case .teeInk:        return (0x2E, 0x33, 0x52, 0xFF)
        case .pinstripe:     return (0x44, 0x48, 0x5C, 0xFF)
        case .uniformBlack:  return (0x24, 0x22, 0x2A, 0xFF)
        case .uniformRed:    return (0xD8, 0x24, 0x38, 0xFF)
        case .deskLight:     return (0xD2, 0xA5, 0x74, 0xFF)
        case .deskDark:      return (0xA8, 0x7B, 0x4E, 0xFF)
        case .keyBody:       return (0xB9, 0xBD, 0xC9, 0xFF)
        case .keyCap:        return (0xE6, 0xE9, 0xF0, 0xFF)
        case .keyShadow:     return (0x83, 0x88, 0x96, 0xFF)
        case .cupBody:       return (0xFA, 0xFA, 0xFA, 0xFF)
        case .cupShade:      return (0xCE, 0xD3, 0xDA, 0xFF)
        case .cupHeart:      return (0xE0, 0x5B, 0x5B, 0xFF)
        case .blush:         return (0xF3, 0xA2, 0xA6, 0xFF)
        case .zzz:           return (0x6B, 0x7A, 0xA8, 0xFF)
        case .steam:         return (0xDE, 0xE6, 0xF0, 0xFF)
        }
    }
}
