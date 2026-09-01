import AppKit
import DeskPetCore

/// 메뉴 막대 아이콘과 설정 메뉴.
final class MenuBarController: NSObject, NSMenuDelegate {

    private let statusItem: NSStatusItem
    private let prefs: Preferences
    private let sound: SoundPlayer
    private let windowController: PetWindowController
    private let keyMonitor: KeyActivityMonitor
    private let pomodoro: PomodoroController

    private let visibilityItem = NSMenuItem()
    private let soundItem = NSMenuItem()
    private let bubbleItem = NSMenuItem()
    private let loginItem = NSMenuItem()
    private let permissionItem = NSMenuItem()
    private let focusItem = NSMenuItem()
    private let focusStatusItem = NSMenuItem()
    private let browserWatchingItem = NSMenuItem()
    private var sizeItems: [PetSize: NSMenuItem] = [:]
    private var frequencyItems: [SpeechFrequency: NSMenuItem] = [:]
    private var outfitItems: [Outfit: NSMenuItem] = [:]
    private var languageItems: [AppLanguage: NSMenuItem] = [:]

    init(prefs: Preferences, sound: SoundPlayer,
         windowController: PetWindowController, keyMonitor: KeyActivityMonitor,
         pomodoro: PomodoroController) {
        self.prefs = prefs
        self.sound = sound
        self.windowController = windowController
        self.keyMonitor = keyMonitor
        self.pomodoro = pomodoro
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        statusItem.button?.image = SpriteImageProvider.menuBarIcon(height: 18)
        statusItem.button?.toolTip = "DeskPet"
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        visibilityItem.title = L10n.t("캐릭터 숨기기", "Hide Character")
        visibilityItem.action = #selector(toggleVisible)
        visibilityItem.target = self
        menu.addItem(visibilityItem)

        focusItem.action = #selector(toggleFocus)
        focusItem.target = self
        menu.addItem(focusItem)

        focusStatusItem.isEnabled = false
        menu.addItem(focusStatusItem)

        let attentionMenu = NSMenu()
        browserWatchingItem.title = L10n.t("브라우저 탭도 감지", "Watch browser tabs")
        browserWatchingItem.action = #selector(toggleBrowserWatching)
        browserWatchingItem.target = self
        attentionMenu.addItem(browserWatchingItem)
        attentionMenu.addItem(.separator())

        let addApp = NSMenuItem(title: L10n.t("현재 앱을 딴짓 목록에 추가", "Add current app as a distraction"), action: #selector(addCurrentApp), keyEquivalent: "")
        addApp.target = self
        attentionMenu.addItem(addApp)
        let addSite = NSMenuItem(title: L10n.t("현재 사이트를 딴짓 목록에 추가", "Add current site as a distraction"), action: #selector(addCurrentSite), keyEquivalent: "")
        addSite.target = self
        attentionMenu.addItem(addSite)
        attentionMenu.addItem(.separator())
        let resetList = NSMenuItem(title: L10n.t("딴짓 목록 비우기", "Clear distraction list"), action: #selector(clearDistractionList), keyEquivalent: "")
        resetList.target = self
        attentionMenu.addItem(resetList)
        let attentionItem = NSMenuItem(title: L10n.t("집중 감지", "Attention Detection"), action: nil, keyEquivalent: "")
        attentionItem.submenu = attentionMenu
        menu.addItem(attentionItem)

        menu.addItem(.separator())

        let sizeMenu = NSMenu()
        for size in PetSize.allCases {
            let item = NSMenuItem(title: size.title, action: #selector(changeSize(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = size.rawValue
            sizeMenu.addItem(item)
            sizeItems[size] = item
        }
        let sizeItem = NSMenuItem(title: L10n.t("크기", "Size"), action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let outfitMenu = NSMenu()
        for outfit in Outfit.allCases {
            let item = NSMenuItem(title: outfit.title, action: #selector(changeOutfit(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = outfit.rawValue
            outfitMenu.addItem(item)
            outfitItems[outfit] = item
        }
        let outfitItem = NSMenuItem(title: L10n.t("옷", "Outfit"), action: nil, keyEquivalent: "")
        outfitItem.submenu = outfitMenu
        menu.addItem(outfitItem)

        menu.addItem(.separator())

        soundItem.title = L10n.t("소리", "Sound")
        soundItem.action = #selector(toggleSound)
        soundItem.target = self
        menu.addItem(soundItem)

        bubbleItem.title = L10n.t("말풍선", "Speech Bubbles")
        bubbleItem.action = #selector(toggleBubbles)
        bubbleItem.target = self
        menu.addItem(bubbleItem)

        let frequencyMenu = NSMenu()
        for frequency in SpeechFrequency.allCases {
            let item = NSMenuItem(title: frequency.title, action: #selector(changeFrequency(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = frequency.rawValue
            frequencyMenu.addItem(item)
            frequencyItems[frequency] = item
        }
        let frequencyItem = NSMenuItem(title: L10n.t("말풍선 빈도", "Bubble Frequency"), action: nil, keyEquivalent: "")
        frequencyItem.submenu = frequencyMenu
        menu.addItem(frequencyItem)

        loginItem.title = L10n.t("로그인 시 자동 실행", "Launch at Login")
        loginItem.action = #selector(toggleLaunchAtLogin)
        loginItem.target = self
        menu.addItem(loginItem)

        let languageMenu = NSMenu()
        for language in AppLanguage.allCases {
            let item = NSMenuItem(title: language.title, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            languageMenu.addItem(item)
            languageItems[language] = item
        }
        let languageItem = NSMenuItem(title: L10n.t("언어", "Language"), action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        menu.addItem(.separator())

        permissionItem.action = #selector(openPermission)
        permissionItem.target = self
        menu.addItem(permissionItem)

        let resetItem = NSMenuItem(title: L10n.t("위치 초기화", "Reset Position"), action: #selector(resetPosition), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: L10n.t("DeskPet 종료", "Quit DeskPet"), action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) { refresh() }

    func refresh() {
        visibilityItem.title = windowController.isVisible
            ? L10n.t("캐릭터 숨기기", "Hide Character")
            : L10n.t("캐릭터 보이기", "Show Character")
        soundItem.state = prefs.soundEnabled ? .on : .off
        bubbleItem.state = prefs.bubblesEnabled ? .on : .off
        browserWatchingItem.state = prefs.attentionWatchBrowser ? .on : .off
        switch pomodoro.phase {
        case .idle, .finished:
            focusItem.title = L10n.t("집중 시작 (\(Int(prefs.pomodoroMinutes))분)", "Start Focus (\(Int(prefs.pomodoroMinutes)) min)")
        case .focusing:
            focusItem.title = L10n.t("집중 일시정지", "Pause Focus")
        case .paused:
            focusItem.title = L10n.t("집중 다시 시작", "Resume Focus")
        }
        let warning = pomodoro.warningCount == 0 ? "" : L10n.t(" · 경고 \(pomodoro.warningCount)회", " · \(pomodoro.warningCount) warnings")
        focusStatusItem.title = L10n.t("집중 타이머: \(pomodoro.timeText)\(warning)", "Focus timer: \(pomodoro.timeText)\(warning)")
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        loginItem.isEnabled = LaunchAtLogin.isSupported
        for (size, item) in sizeItems { item.state = (prefs.size == size) ? .on : .off }
        for (outfit, item) in outfitItems {
            item.state = (prefs.outfit == outfit) ? .on : .off
            item.title = outfit.title
        }
        for (language, item) in languageItems {
            item.state = (prefs.language == language) ? .on : .off
            item.title = language.title
        }
        for (size, item) in sizeItems { item.title = size.title }
        for (frequency, item) in frequencyItems { item.title = frequency.title }
        for (frequency, item) in frequencyItems {
            item.state = (prefs.bubbleFrequency == frequency) ? .on : .off
            item.isEnabled = prefs.bubblesEnabled
        }

        if keyMonitor.isInputMonitoringTrusted && keyMonitor.isGlobalMonitorInstalled {
            permissionItem.title = keyMonitor.isSecureInputEnabled
                ? L10n.t("입력 감지: 잠시 쉬는 중(보안 입력)", "Typing detection: paused (secure input)")
                : L10n.t("입력 감지: 켜짐", "Typing detection: on")
        } else if keyMonitor.isInputMonitoringTrusted {
            permissionItem.title = L10n.t("입력 감지: 앱을 다시 실행해 주세요…", "Typing detection: relaunch required…")
        } else {
            permissionItem.title = L10n.t("입력 모니터링 권한 허용하기…", "Grant Input Monitoring access…")
        }
    }

    // MARK: - 동작

    @objc private func toggleVisible() {
        let next = !windowController.isVisible
        windowController.setVisible(next)
        prefs.isVisible = next
        refresh()
    }

    @objc private func toggleFocus() {
        pomodoro.toggle()
        refresh()
    }

    @objc private func toggleBrowserWatching() {
        prefs.attentionWatchBrowser.toggle()
        refresh()
    }

    @objc private func addCurrentApp() {
        pomodoro.sampleCurrentContext()
        let bundleID = pomodoro.currentAppName
        let id = pomodoro.currentBundleID
        guard !id.isEmpty, !prefs.distractionApps.contains(where: { $0.caseInsensitiveCompare(id) == .orderedSame }) else { return }
        prefs.distractionApps.append(id)
        windowController.model.showHint(L10n.t("\(bundleID)을 딴짓 목록에 추가했어.", "Added \(bundleID) to distractions."), seconds: 3)
        refresh()
    }

    @objc private func addCurrentSite() {
        pomodoro.sampleCurrentContext()
        let host = pomodoro.currentHost
        guard !host.isEmpty, !prefs.distractionSites.contains(where: { $0.caseInsensitiveCompare(host) == .orderedSame }) else { return }
        prefs.distractionSites.append(host)
        windowController.model.showHint(L10n.t("\(host)을 딴짓 목록에 추가했어.", "Added \(host) to distractions."), seconds: 3)
        refresh()
    }

    @objc private func clearDistractionList() {
        prefs.distractionApps = []
        prefs.distractionSites = []
        refresh()
    }

    @objc private func changeSize(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let size = PetSize(rawValue: raw) else { return }
        prefs.size = size
        windowController.applySize(size)
        refresh()
    }

    @objc private func toggleSound() {
        prefs.soundEnabled.toggle()
        sound.isEnabled = prefs.soundEnabled
        refresh()
    }

    @objc private func toggleBubbles() {
        prefs.bubblesEnabled.toggle()
        windowController.model.bubblesEnabled = prefs.bubblesEnabled
        refresh()
    }

    /// 언어를 바꾸면 메뉴 제목까지 그 자리에서 다시 그린다.
    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let language = AppLanguage(rawValue: raw) else { return }
        prefs.language = language
        L10n.setLanguage(language)
        statusItem.menu = buildMenu()
        refresh()
    }

    @objc private func changeOutfit(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let outfit = Outfit(rawValue: raw) else { return }
        prefs.outfit = outfit
        windowController.model.outfit = outfit
        refresh()
    }

    @objc private func changeFrequency(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let frequency = SpeechFrequency(rawValue: raw) else { return }
        prefs.bubbleFrequency = frequency
        windowController.model.bubbleFrequency = frequency
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        let target = !LaunchAtLogin.isEnabled
        if let message = LaunchAtLogin.setEnabled(target) {
            PermissionOnboarding.showMessage(title: L10n.t("자동 실행", "Launch at Login"), message: message)
        }
        refresh()
    }

    @objc private func openPermission() {
        if keyMonitor.isInputMonitoringTrusted && keyMonitor.isGlobalMonitorInstalled {
            PermissionOnboarding.showMessage(
                title: L10n.t("입력 감지가 켜져 있어요", "Typing detection is on"),
                message: L10n.t("타이핑하면 캐릭터도 같이 키보드를 두드려요.\n입력한 내용은 저장하지도, 어디로 보내지도 않아요.",
                                "The character types along when you do.\nWhat you type is never stored or sent anywhere."))
        } else if keyMonitor.isInputMonitoringTrusted {
            PermissionOnboarding.showMessage(
                title: L10n.t("DeskPet을 다시 실행해 주세요", "Please relaunch DeskPet"),
                message: L10n.t("입력 모니터링 권한을 반영하려면 DeskPet을 완전히 종료한 뒤 다시 실행해야 해요.",
                                "Quit DeskPet completely and reopen it to apply Input Monitoring access."))
        } else {
            PermissionOnboarding.requestAccess(keyMonitor: keyMonitor)
        }
        refresh()
    }

    @objc private func resetPosition() {
        windowController.resetPosition()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
