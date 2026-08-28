import Foundation
import CoreGraphics
import TinyTest
import DeskPetCore

final class TypingTrackerTests: XCTestCase {

    func testNoKeysMeansNotTyping() {
        let tracker = TypingTracker()
        XCTAssertFalse(tracker.isTyping(at: 10))
        XCTAssertNil(tracker.typingState(at: 10))
        XCTAssertNil(tracker.secondsSinceLastKey(at: 10))
    }

    func testSlowTyping() {
        var tracker = TypingTracker()
        tracker.registerKeystroke(at: 1.0)
        tracker.registerKeystroke(at: 1.4)
        XCTAssertTrue(tracker.isTyping(at: 1.5))
        XCTAssertEqual(tracker.typingState(at: 1.5), .typingSlow)
    }

    func testFastTypingWhenRateIsHigh() {
        var tracker = TypingTracker()
        for i in 0..<10 { tracker.registerKeystroke(at: 1.0 + Double(i) * 0.1) }
        XCTAssertEqual(tracker.typingState(at: 2.0), .typingFast)
        XCTAssertGreaterThanOrEqual(tracker.keysPerSecond(at: 2.0), 4.0)
    }

    func testReturnsToIdleAfterTimeout() {
        var tracker = TypingTracker()
        tracker.registerKeystroke(at: 5.0)
        XCTAssertTrue(tracker.isTyping(at: 6.4))     // 1.4초 → 아직 타이핑 중
        XCTAssertFalse(tracker.isTyping(at: 6.6))    // 1.6초 → 대기 상태
        XCTAssertNil(tracker.typingState(at: 6.6))
        XCTAssertEqual(tracker.secondsSinceLastKey(at: 6.6) ?? 0, 1.6, accuracy: 0.0001)
    }

    func testOldTimestampsArePrunedSoMemoryStaysSmall() {
        var tracker = TypingTracker()
        for i in 0..<500 { tracker.registerKeystroke(at: Double(i) * 0.05) }
        // 최근 구간만 남으므로 타속이 폭주하지 않는다.
        XCTAssertLessThan(tracker.keysPerSecond(at: 25.0), 30)
    }
}
