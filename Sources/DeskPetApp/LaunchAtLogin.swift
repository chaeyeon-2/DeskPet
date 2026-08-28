import Foundation
import ServiceManagement
import DeskPetCore

/// 로그인 시 자동 실행 (macOS 13+ SMAppService).
enum LaunchAtLogin {

    static var isSupported: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app")
    }

    static var isEnabled: Bool {
        guard isSupported else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// 성공하면 nil, 실패하면 사용자에게 보여 줄 메시지를 돌려준다.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> String? {
        guard isSupported else {
            return L10n.t("자동 실행은 DeskPet.app 으로 실행했을 때만 설정할 수 있어요.",
                          "Launch at login only works when running DeskPet.app.")
        }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
            return nil
        } catch {
            return L10n.t("자동 실행 설정을 바꾸지 못했어요: ", "Could not change the launch-at-login setting: ")
                + error.localizedDescription
        }
    }
}
