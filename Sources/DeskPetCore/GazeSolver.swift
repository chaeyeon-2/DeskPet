import Foundation
import CoreGraphics

public struct Gaze: Sendable, Equatable {
    public var x: Int            // 눈동자 좌우 (-2...2), 화면 좌표 기준 오른쪽이 +
    public var y: Int            // 눈동자 상하 (-1...1), 위쪽이 -
    public var isNear: Bool      // 커서가 캐릭터 가까이 있는지
    public var horizontal: Int   // -1 왼쪽 / 0 정면 / 1 오른쪽 (고개 방향)

    public static let center = Gaze(x: 0, y: 0, isNear: false, horizontal: 0)

    public init(x: Int, y: Int, isNear: Bool, horizontal: Int) {
        self.x = x; self.y = y; self.isNear = isNear; self.horizontal = horizontal
    }
}

/// 커서 위치로부터 시선을 계산한다. AppKit 화면 좌표(위로 +y)를 기준으로 받는다.
public enum GazeSolver {
    public static let awarenessRadius: CGFloat = 460
    public static let turnHeadThreshold: CGFloat = 70

    public static func solve(headCenter: CGPoint,
                             cursor: CGPoint,
                             awarenessRadius: CGFloat = GazeSolver.awarenessRadius) -> Gaze {
        let dx = cursor.x - headCenter.x
        let dy = cursor.y - headCenter.y
        let distance = (dx * dx + dy * dy).squareRoot()
        let isNear = distance <= awarenessRadius
        guard isNear else { return .center }

        // 화면 거리를 눈동자 픽셀 이동량으로 압축한다.
        let nx = max(-1.0, min(1.0, Double(dx) / Double(awarenessRadius * 0.55)))
        let ny = max(-1.0, min(1.0, Double(dy) / Double(awarenessRadius * 0.55)))
        let px = Int((nx * 2).rounded())
        // 스프라이트 y 축은 아래로 증가하므로 부호를 뒤집는다.
        let py = Int((-ny * 1).rounded())
        var horizontal = 0
        if dx > turnHeadThreshold { horizontal = 1 }
        else if dx < -turnHeadThreshold { horizontal = -1 }
        return Gaze(x: max(-2, min(2, px)), y: max(-1, min(1, py)), isNear: true, horizontal: horizontal)
    }
}
