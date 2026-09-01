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
        static let language = "pet.language"
        static let originX = "pet.origin.x"
        static let originY = "pet.origin.y"
        static let hasPosition = "pet.origin.saved"
        static let permissionIntroShown = "pet.permissionIntroShown"
        static let pomodoroMinutes = "pomodoro.minutes"
        static let attentionGraceSeconds = "pomodoro.attentionGraceSeconds"
        static let attentionWatchBrowser = "pomodoro.attentionWatchBrowser"
        static let distractionApps = "pomodoro.distractionApps"
        static let distractionSites = "pomodoro.distractionSites"
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
            Key.outfit: Outfit.checkShirt.rawValue,
            Key.language: AppLanguage.system.rawValue,
            Key.pomodoroMinutes: 25.0,
            Key.attentionGraceSeconds: 6.0,
            Key.attentionWatchBrowser: true,
            Key.distractionApps: ["com.kakao.KakaoTalkMac", "com.apple.MobileSMS", "com.hnc.Discord", "com.netflix.Netflix", "com.tencent.xin"],
            Key.distractionSites: ["youtube.com", "youtu.be", "netflix.com", "twitch.tv", "instagram.com", "x.com", "twitter.com", "reddit.com", "tiktok.com", "dcinside.com", "fmkorea.com", "ruliweb.com", "clien.net", "inven.co.kr", "chzzk.naver.com"]
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

    var language: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Key.language) }
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

    var pomodoroMinutes: Double {
        get { max(1, defaults.double(forKey: Key.pomodoroMinutes)) }
        set { defaults.set(max(1, newValue), forKey: Key.pomodoroMinutes) }
    }

    var attentionGraceSeconds: Double {
        get { max(0, defaults.double(forKey: Key.attentionGraceSeconds)) }
        set { defaults.set(max(0, newValue), forKey: Key.attentionGraceSeconds) }
    }

    var attentionWatchBrowser: Bool {
        get { defaults.bool(forKey: Key.attentionWatchBrowser) }
        set { defaults.set(newValue, forKey: Key.attentionWatchBrowser) }
    }

    var distractionApps: [String] {
        get { defaults.stringArray(forKey: Key.distractionApps) ?? [] }
        set { defaults.set(newValue, forKey: Key.distractionApps) }
    }

    var distractionSites: [String] {
        get { defaults.stringArray(forKey: Key.distractionSites) ?? [] }
        set { defaults.set(newValue, forKey: Key.distractionSites) }
    }
}
