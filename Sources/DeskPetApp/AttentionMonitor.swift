import AppKit

/// 앞에 있는 앱과 지원 브라우저의 현재 탭을 확인한다. URL은 기기 밖으로 전송하지 않는다.
final class AttentionMonitor {
    struct Verdict: Equatable {
        let isDistracting: Bool
        let appName: String
        let detail: String
    }

    static let browsers: [String: String] = [
        "com.google.Chrome": "active tab of front window",
        "com.brave.Browser": "active tab of front window",
        "com.microsoft.edgemac": "active tab of front window",
        "company.thebrowser.dia": "active tab of front window",
        "company.thebrowser.Browser": "active tab of front window",
        "com.naver.Whale": "active tab of front window",
        "com.vivaldi.Vivaldi": "active tab of front window",
        "com.apple.Safari": "current tab of front window"
    ]

    private let scriptQueue = DispatchQueue(label: "deskpet.attention.osascript")
    private let ownBundleID = Bundle.main.bundleIdentifier ?? ""
    private var fetchingURL = false
    private var lastURLFetch = Date.distantPast

    private(set) var frontBundleID = ""
    private(set) var frontAppName = ""
    private(set) var currentURL = ""

    var currentHost: String {
        guard let host = URL(string: currentURL)?.host, !host.isEmpty else { return "" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    func sample(watchBrowserURL: Bool, active: Bool) {
        guard let front = NSWorkspace.shared.frontmostApplication else { return }
        let bundleID = front.bundleIdentifier ?? ""
        guard !bundleID.isEmpty, bundleID != ownBundleID else { return }
        frontBundleID = bundleID
        frontAppName = front.localizedName ?? bundleID

        guard watchBrowserURL, let tab = Self.browsers[bundleID] else {
            currentURL = ""
            return
        }
        let interval: TimeInterval = active ? 1.2 : 4
        guard !fetchingURL, Date().timeIntervalSince(lastURLFetch) >= interval else { return }
        fetchingURL = true
        lastURLFetch = Date()
        let source = "tell application id \"\(bundleID)\" to return URL of \(tab)"
        scriptQueue.async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = Pipe()
            var result = ""
            do {
                try process.run()
                let data = output.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            } catch { }
            DispatchQueue.main.async {
                self?.currentURL = result
                self?.fetchingURL = false
            }
        }
    }

    func verdict(distractionApps: [String], distractionSites: [String]) -> Verdict {
        if distractionApps.contains(where: { $0.caseInsensitiveCompare(frontBundleID) == .orderedSame }) {
            return Verdict(isDistracting: true, appName: frontAppName, detail: "")
        }
        let url = currentURL.lowercased()
        if let site = distractionSites.first(where: { url.contains($0.lowercased()) }) {
            return Verdict(isDistracting: true, appName: frontAppName, detail: site)
        }
        return Verdict(isDistracting: false, appName: frontAppName, detail: "")
    }
}
