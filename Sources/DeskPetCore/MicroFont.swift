import Foundation

/// 티셔츠 문구처럼 아주 작은 글자를 찍기 위한 3×5 픽셀 폰트.
/// 글자 폭이 제각각이라(I 는 1픽셀) 좁은 옷에도 문장이 들어간다.
public enum MicroFont {

    public static let glyphHeight = 5
    public static let letterSpacing = 1

    static let glyphs: [Character: [String]] = [
        "A": [" # ",
              "# #",
              "###",
              "# #",
              "# #"],
        "B": ["## ",
              "# #",
              "## ",
              "# #",
              "## "],
        "I": ["###",
              " # ",
              " # ",
              " # ",
              "###"],
        "K": ["# #",
              "## ",
              "#  ",
              "## ",
              "# #"],
        "L": ["# ",
              "# ",
              "# ",
              "# ",
              "##"],
        "X": ["# #",
              "# #",
              " # ",
              "# #",
              "# #"],
        "O": ["###",
              "# #",
              "# #",
              "# #",
              "###"],
        "V": ["# #",
              "# #",
              "# #",
              "# #",
              " # "],
        "E": ["###",
              "#  ",
              "## ",
              "#  ",
              "###"],
        "G": ["###",
              "#  ",
              "# #",
              "# #",
              "###"],
        "T": ["###",
              " # ",
              " # ",
              " # ",
              " # "],
        "W": ["#   #",
              "#   #",
              "# # #",
              "## ##",
              "#   #"],
        "N": ["#  #",
              "## #",
              "# ##",
              "#  #",
              "#  #"],
        "S": ["###",
              "#  ",
              "###",
              "  #",
              "###"],
        // 4줄짜리 작은 글자 (줄 간격을 벌리기 위해 사용)
        "i": ["###",
              " # ",
              " # ",
              "###"],
        "l": ["# ",
              "# ",
              "# ",
              "##"],
        "g": ["###",
              "#  ",
              "# #",
              "###"],
        // 하트 (5×4)
        "♥": ["## ##",
              "#####",
              " ### ",
              "  #  "],
        " ": ["  ",
              "  ",
              "  ",
              "  ",
              "  "]
    ]

    public static func glyphWidth(_ character: Character) -> Int {
        glyphs[character]?.first?.count ?? 0
    }

    /// 글자 사이 간격까지 포함한 전체 폭.
    public static func width(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let widths = text.map { glyphWidth($0) }
        return widths.reduce(0, +) + letterSpacing * (text.count - 1)
    }

    /// (x, y) 를 왼쪽 위 모서리로 삼아 글자를 찍는다.
    @discardableResult
    public static func draw(_ text: String, into canvas: inout PixelCanvas,
                            x: Int, y: Int, color: PixelColor) -> Int {
        var cursor = x
        for character in text {
            guard let rows = glyphs[character] else { continue }
            for (dy, row) in rows.enumerated() {
                for (dx, pixel) in row.enumerated() where pixel == "#" {
                    canvas.plot(cursor + dx, y + dy, color)
                }
            }
            cursor += glyphWidth(character) + letterSpacing
        }
        return cursor - x - letterSpacing
    }

    /// 주어진 중심선에 맞춰 가운데 정렬로 찍는다.
    @discardableResult
    public static func drawCentered(_ text: String, into canvas: inout PixelCanvas,
                                    centerX: Int, y: Int, color: PixelColor) -> Int {
        draw(text, into: &canvas, x: centerX - width(text) / 2, y: y, color: color)
    }
}
