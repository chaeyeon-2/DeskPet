import Foundation
import CoreGraphics
import TinyTest
import CoreGraphics
import DeskPetCore

final class GazeSolverTests: XCTestCase {

    func testFarCursorIsIgnored() {
        let gaze = GazeSolver.solve(headCenter: CGPoint(x: 500, y: 500),
                                    cursor: CGPoint(x: 1500, y: 500))
        XCTAssertFalse(gaze.isNear)
        XCTAssertEqual(gaze, .center)
    }

    func testCursorOnTheRightTurnsHeadRight() {
        let gaze = GazeSolver.solve(headCenter: CGPoint(x: 500, y: 500),
                                    cursor: CGPoint(x: 700, y: 500))
        XCTAssertTrue(gaze.isNear)
        XCTAssertEqual(gaze.horizontal, 1)
        XCTAssertGreaterThan(gaze.x, 0)
    }

    func testCursorOnTheLeftTurnsHeadLeft() {
        let gaze = GazeSolver.solve(headCenter: CGPoint(x: 500, y: 500),
                                    cursor: CGPoint(x: 300, y: 500))
        XCTAssertEqual(gaze.horizontal, -1)
        XCTAssertLessThan(gaze.x, 0)
    }

    func testCursorAboveLooksUp() {
        // AppKit 좌표는 위가 +y, 스프라이트 좌표는 아래가 +y 이므로 부호가 뒤집힌다.
        let gaze = GazeSolver.solve(headCenter: CGPoint(x: 500, y: 500),
                                    cursor: CGPoint(x: 500, y: 700))
        XCTAssertLessThan(gaze.y, 0)
    }

    func testGazeStaysWithinSpriteLimits() {
        for dx in stride(from: -600.0, through: 600.0, by: 25.0) {
            for dy in stride(from: -600.0, through: 600.0, by: 25.0) {
                let gaze = GazeSolver.solve(headCenter: .zero, cursor: CGPoint(x: dx, y: dy))
                XCTAssertTrue((-2...2).contains(gaze.x))
                XCTAssertTrue((-1...1).contains(gaze.y))
            }
        }
    }
}

final class ScreenPlacementTests: XCTestCase {

    private let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 875),        // 주 화면 (Dock 제외)
        CGRect(x: 1440, y: 200, width: 1920, height: 1080)   // 오른쪽 보조 모니터
    ]

    func testWindowStaysOnScreen() {
        let frame = CGRect(x: 1380, y: -50, width: 220, height: 200)
        let clamped = ScreenPlacement.clamp(frame: frame, into: screens)
        XCTAssertTrue(screens.contains { $0.contains(clamped) })
    }

    func testChoosesScreenWithMostOverlap() {
        let frame = CGRect(x: 3200, y: 1100, width: 220, height: 200)
        let clamped = ScreenPlacement.clamp(frame: frame, into: screens)
        XCTAssertTrue(screens[1].contains(clamped))
        XCTAssertLessThanOrEqual(clamped.maxX, screens[1].maxX)
        XCTAssertLessThanOrEqual(clamped.maxY, screens[1].maxY)
    }

    func testWindowOnDisconnectedScreenComesBack() {
        // 모니터를 뽑아 좌표가 사라진 경우
        let frame = CGRect(x: -3000, y: -3000, width: 220, height: 200)
        let clamped = ScreenPlacement.clamp(frame: frame, into: screens)
        XCTAssertTrue(screens.contains { $0.intersects(clamped) })
    }

    func testDefaultOriginIsBottomRightOfMainScreen() {
        let size = CGSize(width: 220, height: 204)
        let origin = ScreenPlacement.defaultOrigin(size: size, in: screens[0])
        XCTAssertEqual(origin.x, 1440 - 220 - 24)
        XCTAssertEqual(origin.y, 24)
        XCTAssertTrue(screens[0].contains(CGRect(origin: origin, size: size)))
    }

    func testAlreadyVisibleWindowIsNotMoved() {
        let frame = CGRect(x: 400, y: 300, width: 220, height: 200)
        XCTAssertEqual(ScreenPlacement.clamp(frame: frame, into: screens), frame)
    }

    func testEmptyScreenListIsHandled() {
        let frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        XCTAssertEqual(ScreenPlacement.clamp(frame: frame, into: []), frame)
    }
}

final class LocalizationTests: XCTestCase {

    override func tearDown() { L10n.setLanguage(.system) }

    func testLanguageSwitchingChangesUserFacingText() {
        L10n.setLanguage(.korean)
        XCTAssertEqual(L10n.t("크기", "Size"), "크기")
        XCTAssertEqual(PetSize.small.title, "작게")
        XCTAssertEqual(Outfit.orangePuffer.title, "주황 패딩")
        XCTAssertEqual(SpeechFrequency.often.title, "자주")

        L10n.setLanguage(.english)
        XCTAssertEqual(L10n.t("크기", "Size"), "Size")
        XCTAssertEqual(PetSize.small.title, "Small")
        XCTAssertEqual(Outfit.orangePuffer.title, "Orange Puffer")
        XCTAssertEqual(SpeechFrequency.often.title, "Often")
    }

    func testSystemSettingFollowsTheDeviceLanguage() {
        L10n.setLanguage(.system)
        XCTAssertEqual(L10n.isKorean, L10n.systemPrefersKorean)
    }

    func testEveryOutfitAndSizeHasBothLanguages() {
        for language in [AppLanguage.korean, .english] {
            L10n.setLanguage(language)
            for outfit in Outfit.allCases { XCTAssertFalse(outfit.title.isEmpty) }
            for size in PetSize.allCases { XCTAssertFalse(size.title.isEmpty) }
            for frequency in SpeechFrequency.allCases { XCTAssertFalse(frequency.title.isEmpty) }
        }
    }

    func testKoreanAndEnglishTitlesDiffer() {
        L10n.setLanguage(.korean)
        let korean = Outfit.allCases.map(\.title)
        L10n.setLanguage(.english)
        let english = Outfit.allCases.map(\.title)
        XCTAssertNotEqual(korean, english)
    }
}
