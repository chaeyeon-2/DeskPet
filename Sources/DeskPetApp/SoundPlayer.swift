import AppKit

/// 시스템 기본 사운드만 사용한다(별도 음원 파일 없음, 네트워크 없음).
final class SoundPlayer {
    var isEnabled = false

    private var lastKeyClick: TimeInterval = 0
    private let click = NSSound(named: "Tink")
    private let pop = NSSound(named: "Pop")

    init() {
        click?.volume = 0.12
        pop?.volume = 0.25
    }

    func playKeyClick() {
        guard isEnabled, let click else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastKeyClick > 0.12 else { return }   // 너무 자주 울리지 않게
        lastKeyClick = now
        if click.isPlaying { click.stop() }
        click.play()
    }

    func playPoke() {
        guard isEnabled, let pop else { return }
        if pop.isPlaying { pop.stop() }
        pop.play()
    }
}
