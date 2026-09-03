import AppKit
import DeskPetCore

/// `DeskPet --diagnose <로그파일>`
/// 키 입력이 실제로 앱까지 도달하는지 확인한다(내용은 여전히 읽지 않고 횟수만 센다).
final class Diagnose: NSObject {

    private let logURL: URL
    private let monitor = KeyActivityMonitor()
    private var keyCount = 0
    private var lines: [String] = []
    private var elapsed = 0

    init(logURL: URL) {
        self.logURL = logURL
        super.init()
    }

    private func log(_ text: String) {
        lines.append(text)
        try? lines.joined(separator: "\n").write(to: logURL, atomically: true, encoding: .utf8)
    }

    func run(seconds: Int = 20) {
        log("실행 경로: \(Bundle.main.bundlePath)")
        log("번들 ID: \(Bundle.main.bundleIdentifier ?? "(없음)")")
        log("손쉬운 사용(AXIsProcessTrusted): \(monitor.isTrusted)")
        log("입력 모니터링(CGPreflightListenEventAccess): \(monitor.isInputMonitoringTrusted)")
        log("보안 입력(Secure Input): \(monitor.isSecureInputEnabled)")
        log("─────── 지금부터 \(seconds)초간 키 입력을 셉니다 ───────")

        monitor.onKeystroke = { [weak self] in self?.keyCount += 1 }
        monitor.start()
        log("전역 키 이벤트 탭 설치: \(monitor.isGlobalMonitorInstalled)")

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { return }
            self.elapsed += 1
            self.log("\(self.elapsed)초: 감지된 키 입력 누적 \(self.keyCount)회 (입력 모니터링=\(self.monitor.isInputMonitoringTrusted), 이벤트 탭=\(self.monitor.isGlobalMonitorInstalled))")
            if self.elapsed >= seconds {
                t.invalidate()
                self.log("─────── 결과 ───────")
                self.log(self.keyCount > 0
                         ? "정상: 키 입력이 앱까지 도달합니다 (\(self.keyCount)회)"
                         : "문제: 키 입력이 전혀 도달하지 않습니다. 입력 모니터링 권한과 앱 재실행을 확인하세요.")
                exit(0)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
