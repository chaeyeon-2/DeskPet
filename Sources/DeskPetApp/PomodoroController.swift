import Foundation
import DeskPetCore

/// 집중 시간이 흐르는 동안 주의 이탈을 감지한다. 경고 중인 시간은 타이머에서 제외한다.
final class PomodoroController {
    enum Phase { case idle, focusing, paused, finished }

    private let prefs: Preferences
    private let monitor = AttentionMonitor()
    private weak var model: PetViewModel?
    private var ticker: Timer?
    private var endDate: Date?
    private var badSince: Date?
    private var alerting = false
    private var lastAlertText = ""
    private var lastAlertShown = Date.distantPast

    private(set) var phase: Phase = .idle
    private(set) var remaining: TimeInterval = 25 * 60
    private(set) var warningCount = 0
    var onChange: (() -> Void)?

    init(prefs: Preferences, model: PetViewModel) {
        self.prefs = prefs
        self.model = model
        remaining = prefs.pomodoroMinutes * 60
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    deinit { ticker?.invalidate() }

    var isFocusing: Bool { phase == .focusing }
    var timeText: String {
        let seconds = max(0, Int(ceil(remaining)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    var currentAppName: String { monitor.frontAppName }
    var currentBundleID: String { monitor.frontBundleID }
    var currentHost: String { monitor.currentHost }

    func toggle() {
        switch phase {
        case .idle, .finished:
            remaining = prefs.pomodoroMinutes * 60
            warningCount = 0
            endDate = Date().addingTimeInterval(remaining)
            phase = .focusing
            model?.showHint(L10n.t("집중 시작! 옆에서 보고 있을게.", "Focus started! I'll keep watch."), seconds: 4)
        case .focusing:
            phase = .paused
            endDate = nil
            clearAlert()
        case .paused:
            endDate = Date().addingTimeInterval(remaining)
            phase = .focusing
            model?.showHint(L10n.t("다시 집중해 보자.", "Let's get back to it."), seconds: 3)
        }
        publishState()
        onChange?()
    }

    func reset() {
        phase = .idle
        remaining = prefs.pomodoroMinutes * 60
        warningCount = 0
        endDate = nil
        clearAlert()
        publishState()
        onChange?()
    }

    func sampleCurrentContext() {
        monitor.sample(watchBrowserURL: prefs.attentionWatchBrowser, active: isFocusing)
    }

    private func tick() {
        sampleCurrentContext()
        guard phase == .focusing, var end = endDate else { return }
        evaluateAttention()
        if alerting {
            end = end.addingTimeInterval(1)
            endDate = end
            if Date().timeIntervalSince(lastAlertShown) >= 6 {
                lastAlertShown = Date()
                model?.showHint(lastAlertText, seconds: 6)
            }
        }
        remaining = max(0, end.timeIntervalSinceNow)
        if remaining == 0 {
            phase = .finished
            endDate = nil
            clearAlert()
            model?.showHint(L10n.t("집중 완료! 정말 잘했어!", "Focus complete—great work!"), seconds: 6)
        }
        publishState()
        onChange?()
    }

    private func evaluateAttention() {
        let verdict = monitor.verdict(distractionApps: prefs.distractionApps, distractionSites: prefs.distractionSites)
        if verdict.isDistracting {
            if badSince == nil { badSince = Date() }
            guard !alerting, let badSince, Date().timeIntervalSince(badSince) >= prefs.attentionGraceSeconds else { return }
            alerting = true
            warningCount += 1
            let target = verdict.detail.isEmpty ? verdict.appName : verdict.detail
            lastAlertText = L10n.t("\(target) 보고 있네? 집중으로 돌아오자!", "\(target)? Let's return to focus!")
            lastAlertShown = Date()
            model?.showHint(lastAlertText, seconds: 7)
        } else {
            clearAlert()
        }
    }

    private func clearAlert() {
        alerting = false
        badSince = nil
        lastAlertText = ""
        lastAlertShown = .distantPast
    }

    private func publishState() {
        model?.setFocusState(isActive: phase == .focusing || phase == .paused,
                             isPaused: phase == .paused,
                             timeText: timeText,
                             alerting: alerting)
    }
}
