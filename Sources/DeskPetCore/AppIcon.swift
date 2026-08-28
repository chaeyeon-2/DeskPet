import Foundation

/// 앱 아이콘(.icns) 소스를 캐릭터 얼굴로 직접 만든다.
/// 32×32 픽셀 원본을 정수 배율로만 키워서 어떤 크기에서도 픽셀이 선명하다.
public enum AppIcon {

    public static let baseSize = 32

    /// 둥근 사각형 배경 + 캐릭터 얼굴.
    public static func canvas() -> PixelCanvas {
        var c = PixelCanvas(width: baseSize, height: baseSize)

        // 배경: 모서리를 깎은 둥근 사각형
        for y in 0..<baseSize {
            for x in 0..<baseSize {
                let dx = min(x, baseSize - 1 - x)
                let dy = min(y, baseSize - 1 - y)
                let corner = dx + dy
                if corner < 4 { continue }                    // 모서리 깎기
                c.plot(x, y, y < baseSize / 2 ? .lens : .shirt)
            }
        }
        // 배경 테두리
        for y in 0..<baseSize {
            for x in 0..<baseSize where c[x, y] != 0 {
                let neighbours = [(x-1, y), (x+1, y), (x, y-1), (x, y+1)]
                if neighbours.contains(where: { c[$0.0, $0.1] == 0 }) { c.plot(x, y, .outline) }
            }
        }

        // 얼굴만 잘라서 가운데 올린다
        var pose = Pose()
        pose.mouth = .smile
        let sprite = CharacterSprite.render(pose)
        // 머리(외곽선 포함) 영역만 정확히 잘라 온다.
        let cropX = CharacterSprite.headCenterXValue - 13
        let cropY = CharacterSprite.headCenterYValue - 12
        var head = PixelCanvas(width: 27, height: 25)
        for y in 0..<head.height {
            for x in 0..<head.width { head[x, y] = sprite[x + cropX, y + cropY] }
        }
        c.blit(head, dx: (baseSize - head.width) / 2, dy: 4)
        return c
    }

    /// .iconset 폴더에 들어갈 (파일이름, 한 변 픽셀 수) 목록.
    public static let iconSetEntries: [(name: String, pixels: Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]

    @discardableResult
    public static func exportIconSet(to directory: URL) throws -> [String] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let base = canvas()
        let half = base.halved()
        var written: [String] = []
        for entry in iconSetEntries {
            let source = entry.pixels < baseSize ? half : base
            let scale = entry.pixels / source.width
            guard scale >= 1, let data = source.pngData(scale: scale) else { continue }
            try data.write(to: directory.appendingPathComponent(entry.name))
            written.append(entry.name)
        }
        return written
    }
}

public extension PixelCanvas {
    /// 2:1 축소(작은 아이콘용). 2×2 칸에서 비어 있지 않은 픽셀을 고른다.
    func halved() -> PixelCanvas {
        var out = PixelCanvas(width: width / 2, height: height / 2)
        for y in 0..<out.height {
            for x in 0..<out.width {
                let candidates = [self[x*2, y*2], self[x*2+1, y*2], self[x*2, y*2+1], self[x*2+1, y*2+1]]
                out[x, y] = candidates.first { $0 != 0 } ?? 0
            }
        }
        return out
    }
}
