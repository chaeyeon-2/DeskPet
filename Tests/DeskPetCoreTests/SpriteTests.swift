import Foundation
import CoreGraphics
import TinyTest
import DeskPetCore

final class SpriteTests: XCTestCase {

    private func opaqueCount(_ canvas: PixelCanvas) -> Int {
        canvas.pixels.filter { $0 != 0 }.count
    }

    func testCanvasSizeIsStable() {
        let canvas = CharacterSprite.render(Pose())
        XCTAssertEqual(canvas.width, CharacterSprite.canvasWidth)
        XCTAssertEqual(canvas.height, CharacterSprite.canvasHeight)
    }

    func testEveryStateDrawsARealCharacterNotAnEmptyBox() {
        for state in PetState.allCases {
            let animation = AnimationLibrary.animation(for: state)
            XCTAssertFalse(animation.frames.isEmpty, "\(state) 프레임 없음")
            for (i, frame) in animation.frames.enumerated() {
                let canvas = CharacterSprite.render(frame.pose)
                let filled = opaqueCount(canvas)
                XCTAssertGreaterThan(filled, 600, "\(state)_\(i) 픽셀이 너무 적음")
                // 팔레트가 여러 색으로 칠해져 있어야 한다(단색 사각형 방지).
                let distinct = Set(canvas.pixels.filter { $0 != 0 })
                XCTAssertGreaterThan(distinct.count, 8, "\(state)_\(i) 색이 너무 단조로움")
            }
        }
    }

    func testFaceKeepsItsSignatureFeatures() {
        let canvas = CharacterSprite.render(Pose())
        let used = Set(canvas.pixels)
        XCTAssertTrue(used.contains(PixelColor.hair.rawValue), "검은 가르마 머리가 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.glassFrame.rawValue), "사각 안경테가 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.brow.rawValue), "눈썹이 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.shirt.rawValue), "파란 체크 셔츠가 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.eyeWhite.rawValue))
    }

    func testEyebrowsAreVisibleOnSkinNotBuriedUnderHair() {
        let canvas = CharacterSprite.render(Pose())
        var browPixels = 0
        for y in 0..<canvas.height {
            for x in 0..<canvas.width where canvas[x, y] == PixelColor.brow.rawValue {
                browPixels += 1
            }
        }
        XCTAssertGreaterThanOrEqual(browPixels, 10, "눈썹이 머리에 가려졌다")
    }

    func testBlinkClosesTheEyes() {
        var open = Pose(); open.eyeOpen = 1
        var shut = Pose(); shut.eyeOpen = 0
        let openWhite = CharacterSprite.render(open).pixels.filter { $0 == PixelColor.eyeWhite.rawValue }.count
        let shutWhite = CharacterSprite.render(shut).pixels.filter { $0 == PixelColor.eyeWhite.rawValue }.count
        XCTAssertGreaterThan(openWhite, shutWhite)
        XCTAssertEqual(shutWhite, 0)
    }

    func testGazeMovesThePupils() {
        var left = Pose(); left.gazeX = -2
        var right = Pose(); right.gazeX = 2
        XCTAssertNotEqual(CharacterSprite.render(left), CharacterSprite.render(right))
    }

    func testTypingShowsDeskAndKeyboard() {
        var typing = Pose(); typing.showDesk = true; typing.handsOnKeyboard = true
        let canvas = CharacterSprite.render(typing)
        let used = Set(canvas.pixels)
        XCTAssertTrue(used.contains(PixelColor.deskLight.rawValue))
        XCTAssertTrue(used.contains(PixelColor.keyCap.rawValue))
        // 대기 상태에는 책상이 없다.
        XCTAssertFalse(Set(CharacterSprite.render(Pose()).pixels).contains(PixelColor.deskLight.rawValue))
    }

    func testStatesLookDifferentFromEachOther() {
        var seen: [PetState: PixelCanvas] = [:]
        for state in PetState.allCases {
            seen[state] = CharacterSprite.render(AnimationLibrary.animation(for: state).frames[0].pose)
        }
        for a in PetState.allCases {
            for b in PetState.allCases where a != b {
                if a == .idle && b == .blink { continue }   // 첫 프레임이 비슷할 수 있음
                XCTAssertNotEqual(seen[a], seen[b], "\(a) 와 \(b) 가 같아 보인다")
            }
        }
    }

    func testNearestNeighborScalingKeepsPixelsSharp() {
        let canvas = CharacterSprite.render(Pose())
        guard let image = canvas.makeCGImage(),
              let scaled = PixelCanvas.nearestNeighborScale(image, factor: 3) else {
            return XCTFail("이미지를 만들지 못함")
        }
        XCTAssertEqual(scaled.width, canvas.width * 3)
        XCTAssertEqual(scaled.height, canvas.height * 3)
        XCTAssertNotNil(canvas.pngData(scale: 2))
    }

    func testHitTestingUsesOpaquePixels() {
        let canvas = CharacterSprite.render(Pose())
        // 머리 중앙은 캐릭터, 왼쪽 위 모서리는 투명해서 클릭이 통과해야 한다.
        XCTAssertTrue(canvas.isOpaque(x: CharacterSprite.headCenterXValue, y: CharacterSprite.headCenterYValue))
        XCTAssertFalse(canvas.isOpaque(x: 0, y: 0))
        XCTAssertFalse(canvas.isOpaque(x: 63, y: 0))
    }

    func testAnimationTimingPicksTheRightFrame() {
        let animation = AnimationLibrary.animation(for: .typingFast)
        XCTAssertEqual(animation.frameIndex(at: 0), 0)
        XCTAssertEqual(animation.frameIndex(at: animation.totalDuration - 0.001), animation.frames.count - 1)
        // 반복 애니메이션은 처음으로 돌아온다.
        XCTAssertEqual(animation.frameIndex(at: animation.totalDuration + 0.001), 0)

        let oneShot = AnimationLibrary.animation(for: .surprised)
        XCTAssertFalse(oneShot.loops)
        XCTAssertEqual(oneShot.frameIndex(at: 999), oneShot.frames.count - 1)
    }

    func testPetSizesUseIntegerScalingInTheRequestedRange() {
        XCTAssertEqual(PetSize.medium.spriteSize.height, 144)   // 140~180pt 요구사항
        for size in PetSize.allCases {
            XCTAssertEqual(size.spriteSize.width, CGFloat(CharacterSprite.canvasWidth * size.pixelScale))
        }
    }

    func testSpriteExportWritesReplaceableAssets() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("deskpet-sprites-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let files = (try? SpriteExport.exportAll(to: dir, scale: 2)) ?? []
        XCTAssertTrue(files.contains("idle_0.png"))
        XCTAssertTrue(files.contains("_all_states.png"))
        let totalFrames = PetState.allCases.reduce(0) { $0 + AnimationLibrary.animation(for: $1).frames.count }
        XCTAssertEqual(files.count, totalFrames + 2)
    }
}

final class OutfitTests: XCTestCase {

    func testOrangePufferLooksDifferentFromCheckShirt() {
        var shirt = Pose(); shirt.outfit = .checkShirt
        var puffer = Pose(); puffer.outfit = .orangePuffer
        XCTAssertNotEqual(CharacterSprite.render(shirt), CharacterSprite.render(puffer))
    }

    func testPufferUsesOrangePaletteAndQuiltSeams() {
        var pose = Pose(); pose.outfit = .orangePuffer
        let used = Set(CharacterSprite.render(pose).pixels)
        XCTAssertTrue(used.contains(PixelColor.puffer.rawValue), "주황 패딩 색이 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.pufferSeam.rawValue), "누빔선이 있어야 한다")
        XCTAssertTrue(used.contains(PixelColor.zipper.rawValue), "지퍼가 있어야 한다")
        XCTAssertFalse(used.contains(PixelColor.shirt.rawValue), "체크 셔츠 색은 없어야 한다")
    }

    func testFaceStaysTheSameWhenChangingClothes() {
        var shirt = Pose(); shirt.outfit = .checkShirt
        var puffer = Pose(); puffer.outfit = .orangePuffer
        let a = CharacterSprite.render(shirt), b = CharacterSprite.render(puffer)
        // 얼굴(머리 영역)은 옷과 무관하게 동일해야 한다.
        for y in 0..<26 {
            for x in 16..<48 {
                XCTAssertEqual(a[x, y], b[x, y], "얼굴이 옷 때문에 바뀌었다 (\(x),\(y))")
            }
        }
    }

    func testEveryOutfitDrawsProperlyInEveryState() {
        for outfit in Outfit.allCases {
            for state in PetState.allCases {
                for (i, frame) in AnimationLibrary.animation(for: state).frames.enumerated() {
                    var pose = frame.pose
                    pose.outfit = outfit
                    let canvas = CharacterSprite.render(pose)
                    XCTAssertGreaterThan(canvas.pixels.filter { $0 != 0 }.count, 600,
                                         "\(outfit.rawValue) \(state.rawValue)_\(i)")
                }
            }
        }
    }

    func testReplacementSpriteNamesStayCompatible() {
        // 기본 옷은 기존 파일 이름을 그대로 쓴다(이미 만들어 둔 교체 PNG 호환).
        XCTAssertEqual(SpriteExport.fileName(state: .idle, frame: 0), "idle_0.png")
        XCTAssertEqual(SpriteExport.fileName(state: .idle, frame: 0, outfit: .checkShirt), "idle_0.png")
        XCTAssertEqual(SpriteExport.fileName(state: .idle, frame: 0, outfit: .orangePuffer),
                       "orangePuffer_idle_0.png")
    }
}

final class OutfitPrintTests: XCTestCase {

    func testMicroFontMeasuresTextWidth() {
        XCTAssertEqual(MicroFont.width("KIX"), 3 + 1 + 3 + 1 + 3)
        XCTAssertEqual(MicroFont.width("LAB"), 2 + 1 + 3 + 1 + 3)
        XCTAssertGreaterThan(MicroFont.width("TWI"), 0)
        XCTAssertEqual(MicroFont.width(""), 0)
    }

    func testEveryGlyphUsedByOutfitsExists() {
        for character in "IKXLABTWNSlgi♥" {
            XCTAssertGreaterThan(MicroFont.glyphWidth(character), 0, "\(character) 글리프 없음")
        }
    }

    func testMicroFontDrawsInsideTheGivenBox() {
        var canvas = PixelCanvas(width: 20, height: 10)
        let width = MicroFont.draw("KIX", into: &canvas, x: 2, y: 2, color: .teeInk)
        XCTAssertEqual(width, MicroFont.width("KIX"))
        for y in 0..<canvas.height {
            for x in 0..<canvas.width where canvas[x, y] != 0 {
                XCTAssertTrue((2..<(2 + width)).contains(x) && (2..<7).contains(y))
            }
        }
    }

    func testKixlabTeeShowsItsPrint() {
        var pose = Pose(); pose.outfit = .kixlabTee
        let used = Set(CharacterSprite.render(pose).pixels)
        XCTAssertTrue(used.contains(PixelColor.tee.rawValue), "흰 티셔츠")
        XCTAssertTrue(used.contains(PixelColor.teeInk.rawValue), "글자")
        XCTAssertTrue(used.contains(PixelColor.cupHeart.rawValue), "하트")
    }

    func testLGUniformHasPinstripesAndRedLettering() {
        var pose = Pose(); pose.outfit = .lgUniform
        let canvas = CharacterSprite.render(pose)
        let used = Set(canvas.pixels)
        XCTAssertTrue(used.contains(PixelColor.pinstripe.rawValue), "핀스트라이프")
        XCTAssertTrue(used.contains(PixelColor.uniformRed.rawValue), "빨간 글자")
        XCTAssertTrue(used.contains(PixelColor.uniformBlack.rawValue), "어깨 검은 띠")
        // 글자가 팔에 가려지지 않고 충분히 보여야 한다
        let redPixels = canvas.pixels.filter { $0 == PixelColor.uniformRed.rawValue }.count
        XCTAssertGreaterThan(redPixels, 40, "유니폼 글자가 너무 적게 보인다")
    }

    func testPrintStaysInsideTheShirtAndNotOnSkin() {
        for outfit in [Outfit.kixlabTee, .lgUniform] {
            var pose = Pose(); pose.outfit = outfit
            let canvas = CharacterSprite.render(pose)
            let inkColors: [UInt8] = [PixelColor.teeInk.rawValue, PixelColor.uniformRed.rawValue]
            for y in 0..<canvas.height {
                for x in 0..<canvas.width where inkColors.contains(canvas[x, y]) {
                    XCTAssertGreaterThan(y, 28, "\(outfit.rawValue): 글자가 얼굴 위에 그려졌다")
                }
            }
        }
    }

    func testAllFourOutfitsAreDistinct() {
        var canvases: [PixelCanvas] = []
        for outfit in Outfit.allCases {
            var pose = Pose(); pose.outfit = outfit
            canvases.append(CharacterSprite.render(pose))
        }
        for i in 0..<canvases.count {
            for j in (i + 1)..<canvases.count {
                XCTAssertNotEqual(canvases[i], canvases[j])
            }
        }
        XCTAssertEqual(Outfit.allCases.count, 4)
    }
}
