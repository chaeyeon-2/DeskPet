import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// 저해상도 픽셀 버퍼. 한 픽셀 = 팔레트 인덱스 1바이트.
/// 좌표계는 좌상단 (0,0) 기준이며 y는 아래로 증가한다.
public struct PixelCanvas: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public private(set) var pixels: [UInt8]

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: max(0, width * height))
    }

    @inline(__always)
    public func index(_ x: Int, _ y: Int) -> Int? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return y * width + x
    }

    public subscript(x: Int, y: Int) -> UInt8 {
        get { index(x, y).map { pixels[$0] } ?? 0 }
        set { if let i = index(x, y) { pixels[i] = newValue } }
    }

    public func isOpaque(x: Int, y: Int) -> Bool { self[x, y] != 0 }

    // MARK: - 그리기 기본 도구

    public mutating func plot(_ x: Int, _ y: Int, _ color: PixelColor) {
        guard color != .clear, let i = index(x, y) else { return }
        pixels[i] = color.rawValue
    }

    /// 이미 칠해진 픽셀 위에만 덧칠한다(음영 넣을 때 사용).
    public mutating func shade(_ x: Int, _ y: Int, _ color: PixelColor) {
        guard let i = index(x, y), pixels[i] != 0 else { return }
        pixels[i] = color.rawValue
    }

    public mutating func fillRect(x: Int, y: Int, w: Int, h: Int, _ color: PixelColor) {
        guard w > 0, h > 0 else { return }
        for yy in y..<(y + h) {
            for xx in x..<(x + w) { plot(xx, yy, color) }
        }
    }

    public mutating func hLine(_ x0: Int, _ x1: Int, _ y: Int, _ color: PixelColor) {
        for x in min(x0, x1)...max(x0, x1) { plot(x, y, color) }
    }

    public mutating func vLine(_ x: Int, _ y0: Int, _ y1: Int, _ color: PixelColor) {
        for y in min(y0, y1)...max(y0, y1) { plot(x, y, color) }
    }

    /// 정수 반지름 타원 채우기(픽셀아트용 대칭 형태).
    public mutating func fillEllipse(cx: Int, cy: Int, rx: Int, ry: Int, _ color: PixelColor) {
        guard rx >= 0, ry >= 0 else { return }
        for dy in -ry...ry {
            let t = ry == 0 ? 0 : Double(dy) / Double(ry)
            let half = Int((Double(rx) * (1 - t * t).squareRoot()).rounded())
            guard half >= 0 else { continue }
            for dx in -half...half { plot(cx + dx, cy + dy, color) }
        }
    }

    public func ellipseContains(cx: Int, cy: Int, rx: Int, ry: Int, x: Int, y: Int) -> Bool {
        guard rx > 0, ry > 0 else { return false }
        let nx = Double(x - cx) / Double(rx)
        let ny = Double(y - cy) / Double(ry)
        return nx * nx + ny * ny <= 1.0
    }

    /// 모서리를 1픽셀 깎은 사각형(둥근 느낌).
    public mutating func roundedRect(x: Int, y: Int, w: Int, h: Int, _ color: PixelColor) {
        fillRect(x: x, y: y, w: w, h: h, color)
        for (cx, cy) in [(x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)] {
            if let i = index(cx, cy) { pixels[i] = 0 }
        }
    }

    /// 다른 캔버스를 겹쳐 그린다. shearPerRow 로 머리 기울이기를 표현한다.
    public mutating func blit(_ other: PixelCanvas, dx: Int, dy: Int,
                              shearPerRow: Double = 0, pivotY: Int = 0) {
        for y in 0..<other.height {
            let shift = shearPerRow == 0 ? 0 : Int((Double(y - pivotY) * -shearPerRow).rounded())
            for x in 0..<other.width {
                let v = other[x, y]
                if v != 0 { self[dx + x + shift, dy + y] = v }
            }
        }
    }

    // MARK: - 이미지 변환

    public func rgbaBytes() -> [UInt8] {
        var out = [UInt8](repeating: 0, count: width * height * 4)
        var lut = [(UInt8, UInt8, UInt8, UInt8)](repeating: (0, 0, 0, 0), count: 256)
        for c in PixelColor.allCases { lut[Int(c.rawValue)] = c.rgba }
        for i in 0..<(width * height) {
            let (r, g, b, a) = lut[Int(pixels[i])]
            // premultiplied alpha (CGImage premultipliedLast)
            out[i * 4 + 0] = a == 0 ? 0 : r
            out[i * 4 + 1] = a == 0 ? 0 : g
            out[i * 4 + 2] = a == 0 ? 0 : b
            out[i * 4 + 3] = a
        }
        return out
    }

    public func makeCGImage() -> CGImage? {
        var bytes = rgbaBytes()
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        bytes.removeAll()
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)
    }

    public func pngData(scale: Int = 1) -> Data? {
        guard var image = makeCGImage() else { return nil }
        if scale > 1, let scaled = PixelCanvas.nearestNeighborScale(image, factor: scale) {
            image = scaled
        }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    /// 확대해도 흐려지지 않도록 nearest-neighbor 로만 키운다.
    public static func nearestNeighborScale(_ image: CGImage, factor: Int) -> CGImage? {
        guard factor > 1 else { return image }
        let w = image.width * factor, h = image.height * factor
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }
}
