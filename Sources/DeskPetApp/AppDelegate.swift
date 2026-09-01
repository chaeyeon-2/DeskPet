import AppKit
import DeskPetCore

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let prefs = Preferences.shared
    private let sound = SoundPlayer()
    private let keyMonitor = KeyActivityMonitor()
    private var windowController: PetWindowController!
    private var menuBar: MenuBarController!
    private var pomodoro: PomodoroController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 없이 메뉴 막대에서만 동작한다.
        NSApp.setActivationPolicy(.accessory)
        L10n.setLanguage(prefs.language)

        sound.isEnabled = prefs.soundEnabled
        windowController = PetWindowController(prefs: prefs, sound: sound)
        windowController.model.bubblesEnabled = prefs.bubblesEnabled
        windowController.model.bubbleFrequency = prefs.bubbleFrequency
        pomodoro = PomodoroController(prefs: prefs, model: windowController.model)

        menuBar = MenuBarController(prefs: prefs, sound: sound,
                                    windowController: windowController, keyMonitor: keyMonitor,
                                    pomodoro: pomodoro)
        pomodoro.onChange = { [weak self] in self?.menuBar.refresh() }

        keyMonitor.onKeystroke = { [weak self] in
            self?.windowController.registerKeystroke()
        }
        keyMonitor.onPermissionChange = { [weak self] inputMonitoringGranted in
            guard let self else { return }
            self.menuBar.refresh()
            if inputMonitoringGranted {
                self.windowController.model.showHint(
                    L10n.t("입력 감지 켜졌어! 이제 같이 칠 수 있다!", "Input monitoring is on—now we can type together!"), seconds: 4)
            }
        }
        keyMonitor.start()

        windowController.setVisible(prefs.isVisible)
        menuBar.refresh()

        // 캐릭터를 먼저 보여 준 뒤 안내창을 띄운다(시작을 막지 않는다).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            PermissionOnboarding.showIntroIfNeeded(prefs: self.prefs, keyMonitor: self.keyMonitor)
        }
        // 권한이 없으면 캐릭터가 한 번 알려 준다(모달 대신 말풍선으로).
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self, !self.keyMonitor.isInputMonitoringTrusted else { return }
            self.windowController.model.showHint(
                L10n.t("입력 모니터링 켜 주면 같이 타자 칠게", "Turn on Input Monitoring and I'll type along"),
                seconds: 6)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowController?.savePosition()
        keyMonitor.stop()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
