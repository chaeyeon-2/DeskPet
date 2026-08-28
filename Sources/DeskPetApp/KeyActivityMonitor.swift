import AppKit
import Carbon.HIToolbox

/// macOS 전체의 키 입력을 "눌렸다는 사실"만 감지한다.
///
/// 개인정보 원칙
/// ─────────────
/// - 이벤트의 characters / keyCode / modifierFlags 를 읽지 않는다.
/// - 어떤 앱에서 입력했는지도 확인하지 않는다.
/// - 저장하는 것은 상위 계층의 "마지막 입력 시각"뿐이며 네트워크 전송은 전혀 없다.
final class KeyActivityMonitor {

    /// 키가 눌렸을 때 호출된다. 매개변수 없음 = 내용이 전달될 수 없음.
    var onKeystroke: (() -> Void)?
    /// 권한 상태가 바뀌면 호출된다.
    var onPermissionChange: ((Bool) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var permissionTimer: Timer?
    private(set) var lastKnownTrust = false

    var isTrusted: Bool { AXIsProcessTrusted() }

    /// 암호 입력 등 보안 입력 중에는 어떤 앱도 키 이벤트를 받을 수 없다(정상 동작).
    var isSecureInputEnabled: Bool { IsSecureEventInputEnabled() }

    func start() {
        lastKnownTrust = isTrusted
        installMonitors()
        // 사용자가 나중에 권한을 켜면 자동으로 다시 붙는다.
        let timer = Timer(timeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let trusted = self.isTrusted
            if trusted != self.lastKnownTrust {
                self.lastKnownTrust = trusted
                self.installMonitors()
                self.onPermissionChange?(trusted)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func installMonitors() {
        removeMonitors()
        // 권한이 없으면 global 모니터는 조용히 아무 이벤트도 받지 않는다(앱은 계속 동작).
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            self?.onKeystroke?()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.onKeystroke?()
            return event
        }
    }

    private func removeMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    func stop() {
        removeMonitors()
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    /// 시스템 권한 요청 창을 띄운다(이미 허용했다면 아무 일도 일어나지 않는다).
    @discardableResult
    func requestPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    deinit { stop() }
}
