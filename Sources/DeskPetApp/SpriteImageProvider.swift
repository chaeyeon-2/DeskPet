import AppKit
import DeskPetCore

/// 픽셀 캔버스를 화면용 NSImage 로 바꾼다.
///
/// 자산 교체 규칙
/// ─────────────
/// 아래 폴더에 `<상태이름>_<프레임번호>.png` 를 넣으면 그 그림이 우선 사용된다.
///   ~/Library/Application Support/DeskPet/Sprites/
/// 예) idle_0.png, typingFast_2.png, sulking_1.png
/// 파일이 없으면 코드로 그린 기본 픽셀아트를 사용한다.
enum SpriteImageProvider {

    static var overrideDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("DeskPet/Sprites", isDirectory: true)
    }

    private static var overrideCache: [String: NSImage] = [:]
    private static var canvasCache: [Pose: PixelCanvas] = [:]

    /// 교체용 PNG 가 있으면 그것을, 없으면 코드로 그린 스프라이트를 돌려준다.
    static func image(for pose: Pose, state: PetState, frame: Int, size: CGSize) -> NSImage {
        if let custom = overrideImage(state: state, frame: frame, outfit: pose.outfit) {
            custom.size = size
            return custom
        }
        return image(for: canvas(for: pose), size: size)
    }

    static func canvas(for pose: Pose) -> PixelCanvas {
        if let cached = canvasCache[pose] { return cached }
        let canvas = CharacterSprite.render(pose)
        if canvasCache.count > 240 { canvasCache.removeAll(keepingCapacity: true) }
        canvasCache[pose] = canvas
        return canvas
    }

    /// nearest-neighbor 로만 확대해 픽셀이 흐려지지 않게 한다.
    static func image(for canvas: PixelCanvas, size: CGSize) -> NSImage {
        guard let cg = canvas.makeCGImage() else { return NSImage(size: size) }
        return NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.interpolationQuality = .none
            ctx.setShouldAntialias(false)
            ctx.draw(cg, in: rect)
            return true
        }
    }

    private static func overrideImage(state: PetState, frame: Int, outfit: Outfit) -> NSImage? {
        let name = SpriteExport.fileName(state: state, frame: frame, outfit: outfit)
        if let cached = overrideCache[name] { return cached.copy() as? NSImage }
        let url = overrideDirectory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path),
              let image = NSImage(contentsOf: url) else { return nil }
        overrideCache[name] = image
        return image.copy() as? NSImage
    }

    static func clearOverrideCache() {
        overrideCache.removeAll()
    }

    /// 메뉴 막대용 작은 얼굴 아이콘.
    static func menuBarIcon(height: CGFloat = 18) -> NSImage {
        var pose = Pose()
        pose.mouth = .smile
        let full = CharacterSprite.render(pose)
        // 머리 부분만 잘라 쓴다.
        var head = PixelCanvas(width: 26, height: 26)
        for y in 0..<26 {
            for x in 0..<26 {
                head[x, y] = full[x + 19, y + 3]
            }
        }
        let image = self.image(for: head, size: CGSize(width: height, height: height))
        image.isTemplate = false
        return image
    }
}
