import Foundation
import CoreGraphics
import DeskPetCore

/// 사용자 설정 저장소. 앱을 다시 켜도 마지막 상태가 복원된다.
final class Preferences {
    static let shared = Preferences()

    private enum Key {
        static let visible = "pet.visible"
        static let sound = "pet.sound"
        static let bubbles = "pet.bubbles"
        static let bubbleFrequency = "pet.bubbleFrequency"
        static let size = "pet.size"
        static let outfit = "pet.outfit"
        static let originX = "pet.origin.x"
        static let originY = "pet.origin.y"
        static let hasPosition = "pet.origin.saved"
        static let permissionIntroShown = "pet.permissionIntroShown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.visible: true,
            Key.sound: false,
            Key.bubbles: true,
            Key.bubbleFrequency: SpeechFrequency.normal.rawValue,
            Key.size: PetSize.medium.rawValue,
            Key.outfit: Outfit.checkShirt.rawValue
        ])
    }

    var isVisible: Bool {
        get { defaults.bool(forKey: Key.visible) }
        set { defaults.set(newValue, forKey: Key.visible) }
    }

    var soundEnabled: Bool {
        get { defaults.bool(forKey: Key.sound) }
        set { defaults.set(newValue, forKey: Key.sound) }
    }

    var bubblesEnabled: Bool {
        get { defaults.bool(forKey: Key.bubbles) }
        set { defaults.set(newValue, forKey: Key.bubbles) }
    }

    var bubbleFrequency: SpeechFrequency {
        get { SpeechFrequency(rawValue: defaults.string(forKey: Key.bubbleFrequency) ?? "") ?? .normal }
        set { defaults.set(newValue.rawValue, forKey: Key.bubbleFrequency) }
    }

    var size: PetSize {
        get { PetSize(rawValue: defaults.string(forKey: Key.size) ?? "") ?? .medium }
        set { defaults.set(newValue.rawValue, forKey: Key.size) }
    }

    var outfit: Outfit {
        get { Outfit(rawValue: defaults.string(forKey: Key.outfit) ?? "") ?? .checkShirt }
        set { defaults.set(newValue.rawValue, forKey: Key.outfit) }
    }

    var savedOrigin: CGPoint? {
        get {
            guard defaults.bool(forKey: Key.hasPosition) else { return nil }
            return CGPoint(x: defaults.double(forKey: Key.originX),
                           y: defaults.double(forKey: Key.originY))
        }
        set {
            guard let newValue else {
                defaults.set(false, forKey: Key.hasPosition)
                return
            }
            defaults.set(newValue.x, forKey: Key.originX)
            defaults.set(newValue.y, forKey: Key.originY)
            defaults.set(true, forKey: Key.hasPosition)
        }
    }

    var permissionIntroShown: Bool {
        get { defaults.bool(forKey: Key.permissionIntroShown) }
        set { defaults.set(newValue, forKey: Key.permissionIntroShown) }
    }
}
