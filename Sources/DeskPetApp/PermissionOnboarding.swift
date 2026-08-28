import AppKit
import DeskPetCore

/// 권한 안내를 쉬운 한국어로 보여 준다. 거부해도 앱은 그대로 동작한다.
enum PermissionOnboarding {

    /// 권한이 없을 때만 안내한다.
    /// - 처음 실행: 왜 필요한지 설명하는 창을 보여 준다.
    /// - 그 뒤 실행: 시스템 권한 목록에 DeskPet 이 등록되도록 표준 프롬프트만 조용히 띄운다.
    static func showIntroIfNeeded(prefs: Preferences, keyMonitor: KeyActivityMonitor) {
        guard !keyMonitor.isTrusted else { return }
        if prefs.permissionIntroShown {
            keyMonitor.requestPermission()      // 손쉬운 사용 목록에 앱을 등록시킨다
        } else {
            prefs.permissionIntroShown = true
            requestAccess(keyMonitor: keyMonitor, isFirstRun: true)
        }
    }

    static func requestAccess(keyMonitor: KeyActivityMonitor, isFirstRun: Bool = false) {
        let alert = NSAlert()
        alert.messageText = L10n.t("타이핑을 따라 하려면 권한이 하나 필요해요",
                                   "One permission is needed to type along")
        alert.informativeText = L10n.t("""
        캐릭터가 여러분이 타자를 칠 때 같이 키보드를 두드리게 하려면
        macOS 의 손쉬운 사용(입력 감지) 권한이 필요합니다.

        • 앱은 "키가 눌렸다는 사실"과 "마지막 입력 시각"만 사용합니다.
        • 어떤 글자를 눌렀는지, 비밀번호, 사용 중인 앱은 읽지도 저장하지도 않습니다.
        • 인터넷으로 아무것도 보내지 않습니다.

        권한을 주지 않아도 캐릭터는 계속 잘 지냅니다. (대기 동작만 해요)
        """, """
        To make the character type along with you, DeskPet needs
        macOS Accessibility (input monitoring) permission.

        • The app only uses "a key was pressed" and "when it happened".
        • It never reads or stores which key, your passwords, or which app you use.
        • It sends nothing over the internet.

        Without the permission the character still works fine — it just idles.
        """)
        alert.addButton(withTitle: L10n.t("시스템 설정 열기", "Open System Settings"))
        alert.addButton(withTitle: isFirstRun ? L10n.t("나중에 할게요", "Later") : L10n.t("닫기", "Close"))
        alert.alertStyle = .informational

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            keyMonitor.requestPermission()
            KeyActivityMonitor.openAccessibilitySettings()
        }
    }

    static func showMessage(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: L10n.t("확인", "OK"))
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
