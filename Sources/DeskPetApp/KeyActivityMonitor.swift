import AppKit
import ApplicationServices
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

    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var localMonitor: Any?
    private var permissionTimer: Timer?
    private(set) var lastKnownTrust = false
    private(set) var lastKnownInputMonitoring = false

    var isTrusted: Bool { AXIsProcessTrusted() }

    /// macOS 10.15부터 다른 앱의 키 입력을 받으려면 손쉬운 사용과 별도로
    /// '입력 모니터링' 권한이 필요할 수 있다.
    var isInputMonitoringTrusted: Bool { CGPreflightListenEventAccess() }
    var isGlobalMonitorInstalled: Bool { eventTap != nil }

    /// 암호 입력 등 보안 입력 중에는 어떤 앱도 키 이벤트를 받을 수 없다(정상 동작).
    var isSecureInputEnabled: Bool { IsSecureEventInputEnabled() }

    func start() {
        lastKnownTrust = isTrusted
        lastKnownInputMonitoring = isInputMonitoringTrusted
        installMonitors()
        // 사용자가 나중에 권한을 켜면 자동으로 다시 붙는다.
        let timer = Timer(timeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let accessibility = self.isTrusted
            let inputMonitoring = self.isInputMonitoringTrusted
            if accessibility != self.lastKnownTrust
                || inputMonitoring != self.lastKnownInputMonitoring
                || (inputMonitoring && !self.isGlobalMonitorInstalled) {
                self.lastKnownTrust = accessibility
                self.lastKnownInputMonitoring = inputMonitoring
                self.installMonitors()
                self.onPermissionChange?(inputMonitoring)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func installMonitors() {
        removeMonitors()

        // NSEvent 전역 모니터는 설치 성공 여부를 확인할 수 없다. CGEventTap은
        // 실제 입력 모니터링 권한이 없으면 nil을 반환하므로 상태를 정확히 알 수 있다.
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: Self.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) {
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            eventTap = tap
            eventTapSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }

        // 앱 자체가 키 윈도우가 되는 진단/안내 상황에서도 입력을 센다.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.onKeystroke?()
            return event
        }
    }

    private func removeMonitors() {
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
        if let eventTap { CFMachPortInvalidate(eventTap) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        eventTapSource = nil
        eventTap = nil
        localMonitor = nil
    }

    private func receiveEvent(type: CGEventType) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return
        }
        if type == .keyDown { onKeystroke?() }
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<KeyActivityMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        monitor.receiveEvent(type: type)
        return Unmanaged.passUnretained(event)
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
        let accessibilityGranted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        let inputMonitoringGranted = CGRequestListenEventAccess()
        return accessibilityGranted || inputMonitoringGranted
    }

    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }

    deinit { stop() }
}
