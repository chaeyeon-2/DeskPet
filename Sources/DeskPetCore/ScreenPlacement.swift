import Foundation
import CoreGraphics

/// 여러 모니터 환경에서 캐릭터 창이 화면 밖으로 나가지 않게 잡아 준다.
public enum ScreenPlacement {

    /// frame 과 가장 많이 겹치는 화면을 고르고, 없으면 중심이 가장 가까운 화면을 고른다.
    public static func bestScreen(for frame: CGRect, in visibleFrames: [CGRect]) -> CGRect? {
        guard !visibleFrames.isEmpty else { return nil }
        var best: CGRect?
        var bestArea: CGFloat = 0
        for v in visibleFrames {
            let inter = v.intersection(frame)
            let area = inter.isNull ? 0 : inter.width * inter.height
            if area > bestArea { bestArea = area; best = v }
        }
        if let best, bestArea > 0 { return best }
        return visibleFrames.min {
            distance($0.center, frame.center) < distance($1.center, frame.center)
        }
    }

    /// 창이 보이는 영역 안에 들어오도록 위치를 보정한다.
    public static func clamp(frame: CGRect, into visibleFrames: [CGRect], margin: CGFloat = 2) -> CGRect {
        guard let screen = bestScreen(for: frame, in: visibleFrames) else { return frame }
        var f = frame
        let minX = screen.minX + margin
        let maxX = screen.maxX - margin - f.width
        let minY = screen.minY + margin
        let maxY = screen.maxY - margin - f.height
        f.origin.x = maxX >= minX ? min(max(f.origin.x, minX), maxX) : screen.midX - f.width / 2
        f.origin.y = maxY >= minY ? min(max(f.origin.y, minY), maxY) : screen.midY - f.height / 2
        return f
    }

    /// 첫 실행 위치: 주 화면 오른쪽 아래.
    public static func defaultOrigin(size: CGSize, in visibleFrame: CGRect, inset: CGFloat = 24) -> CGPoint {
        CGPoint(x: visibleFrame.maxX - size.width - inset,
                y: visibleFrame.minY + inset)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
