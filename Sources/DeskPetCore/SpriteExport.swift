import Foundation

/// 스프라이트를 PNG 로 뽑아내는 도구.
/// `DeskPet --export-sprites <폴더>` 로 실행하면 현재 픽셀아트를 파일로 확인/교체용 참고본으로 쓸 수 있다.
public enum SpriteExport {

    public static func fileName(state: PetState, frame: Int, outfit: Outfit = .checkShirt) -> String {
        outfit == .checkShirt
            ? "\(state.rawValue)_\(frame).png"
            : "\(outfit.rawValue)_\(state.rawValue)_\(frame).png"
    }

    @discardableResult
    public static func exportAll(to directory: URL, scale: Int = 4) throws -> [String] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var written: [String] = []
        for state in PetState.allCases {
            let anim = AnimationLibrary.animation(for: state)
            for (i, frame) in anim.frames.enumerated() {
                let canvas = CharacterSprite.render(frame.pose)
                guard let data = canvas.pngData(scale: scale) else { continue }
                let name = fileName(state: state, frame: i)
                try data.write(to: directory.appendingPathComponent(name))
                written.append(name)
            }
        }
        if let sheet = outfitSheet().pngData(scale: scale) {
            try sheet.write(to: directory.appendingPathComponent("_outfits.png"))
            written.append("_outfits.png")
        }
        if let sheet = contactSheet().pngData(scale: scale) {
            try sheet.write(to: directory.appendingPathComponent("_all_states.png"))
            written.append("_all_states.png")
        }
        return written
    }

    /// 옷별 미리보기 시트(디자인 확인용).
    public static func outfitSheet() -> PixelCanvas {
        let states: [PetState] = [.idle, .typingFast, .drinkCoffee, .surprised]
        let cw = CharacterSprite.canvasWidth, ch = CharacterSprite.canvasHeight
        var sheet = PixelCanvas(width: cw * states.count, height: ch * Outfit.allCases.count)
        for (row, outfit) in Outfit.allCases.enumerated() {
            for (col, state) in states.enumerated() {
                var pose = AnimationLibrary.animation(for: state).frames[0].pose
                pose.outfit = outfit
                sheet.blit(CharacterSprite.render(pose), dx: col * cw, dy: row * ch)
            }
        }
        return sheet
    }

    /// 모든 상태를 한 장에 모아 보는 시트(디자인 확인용).
    public static func contactSheet() -> PixelCanvas {
        let states = PetState.allCases
        let maxFrames = states.map { AnimationLibrary.animation(for: $0).frames.count }.max() ?? 1
        let cw = CharacterSprite.canvasWidth
        let ch = CharacterSprite.canvasHeight
        var sheet = PixelCanvas(width: cw * maxFrames, height: ch * states.count)
        for (row, state) in states.enumerated() {
            let anim = AnimationLibrary.animation(for: state)
            for (col, frame) in anim.frames.enumerated() {
                sheet.blit(CharacterSprite.render(frame.pose), dx: col * cw, dy: row * ch)
            }
        }
        return sheet
    }
}
