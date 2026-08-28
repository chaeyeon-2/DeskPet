import Foundation
import CoreGraphics
import TinyTest
import DeskPetCore

final class PetBrainTests: XCTestCase {

    private func brain(random: @escaping () -> Double = { 0.5 }) -> PetBrain {
        PetBrain(now: 0, random: random)
    }

    func testStartsIdle() {
        let b = brain()
        XCTAssertEqual(b.update(now: 0.1, gaze: .center).state, .idle)
    }

    func testTypingSwitchesToTypingState() {
        let b = brain()
        b.registerKeystroke(at: 1.0)
        XCTAssertEqual(b.update(now: 1.05, gaze: .center).state, .typingSlow)

        for i in 0..<10 { b.registerKeystroke(at: 2.0 + Double(i) * 0.08) }
        XCTAssertEqual(b.update(now: 2.85, gaze: .center).state, .typingFast)
    }

    func testTypingPoseShowsDeskKeyboardAndMovingHands() {
        let b = brain()
        b.registerKeystroke(at: 1.0)
        let render = b.update(now: 1.05, gaze: .center)
        XCTAssertTrue(render.pose.showDesk)
        XCTAssertTrue(render.pose.handsOnKeyboard)

        let anim = AnimationLibrary.animation(for: .typingFast)
        let lifts = anim.frames.map { ($0.pose.leftHandLift, $0.pose.rightHandLift) }
        XCTAssertTrue(lifts.contains { $0.0 > 0 })   // 왼손이 올라가는 프레임
        XCTAssertTrue(lifts.contains { $0.1 > 0 })   // 오른손이 올라가는 프레임
        XCTAssertTrue(anim.frames.contains { $0.pose.keyboardPress > 0 })  // 키보드가 눌리는 프레임
    }

    func testFastTypingAnimatesFasterThanSlow() {
        let slow = AnimationLibrary.animation(for: .typingSlow)
        let fast = AnimationLibrary.animation(for: .typingFast)
        XCTAssertLessThan(fast.totalDuration, slow.totalDuration)
    }

    func testReturnsToIdleAfterTypingStops() {
        let b = brain()
        b.registerKeystroke(at: 1.0)
        XCTAssertEqual(b.update(now: 1.05, gaze: .center).state, .typingSlow)
        XCTAssertEqual(b.update(now: 2.6, gaze: .center).state, .idle)   // 1.6초 후
    }

    func testClickMakesCharacterSurprised() {
        let b = brain()
        b.registerClick(onHead: false, at: 1.0)
        let render = b.update(now: 1.05, gaze: .center)
        XCTAssertEqual(render.state, .surprised)
        XCTAssertEqual(render.pose.mouth, .open)
        // 잠깐 유지되다가 스스로 풀린다.
        XCTAssertEqual(b.update(now: 1.4, gaze: .center).state, .surprised)
        XCTAssertNotEqual(b.update(now: 3.0, gaze: .center).state, .surprised)
    }

    func testThreeHeadClicksMakeCharacterSulk() {
        let b = brain()
        b.registerClick(onHead: true, at: 1.0)
        b.registerClick(onHead: true, at: 1.3)
        b.registerClick(onHead: true, at: 1.6)
        let render = b.update(now: 1.65, gaze: .center)
        XCTAssertEqual(render.state, .sulking)
        XCTAssertEqual(render.pose.mouth, .wavy)
    }

    func testSlowHeadClicksDoNotSulk() {
        let b = brain()
        b.registerClick(onHead: true, at: 1.0)
        b.registerClick(onHead: true, at: 5.0)
        b.registerClick(onHead: true, at: 9.0)
        XCTAssertEqual(b.update(now: 9.05, gaze: .center).state, .surprised)
    }

    func testCursorNearbyMakesCharacterLook() {
        let b = brain()
        let right = Gaze(x: 2, y: 0, isNear: true, horizontal: 1)
        XCTAssertEqual(b.update(now: 1.0, gaze: right).state, .lookRight)
        let left = Gaze(x: -2, y: 0, isNear: true, horizontal: -1)
        XCTAssertEqual(b.update(now: 1.2, gaze: left).state, .lookLeft)
        XCTAssertEqual(b.update(now: 1.4, gaze: .center).state, .idle)
    }

    func testGazeMovesPupilsWhileIdle() {
        let b = brain()
        let near = Gaze(x: 2, y: -1, isNear: true, horizontal: 0)
        let render = b.update(now: 1.0, gaze: near)
        XCTAssertEqual(render.state, .idle)
        XCTAssertEqual(render.pose.gazeX, 2)
        XCTAssertEqual(render.pose.gazeY, -1)
    }

    func testBlinkHappensOnItsOwn() {
        let b = brain()
        var sawBlink = false
        var t = 0.0
        while t < 12 {
            if b.update(now: t, gaze: .center).state == .blink { sawBlink = true; break }
            t += 0.05
        }
        XCTAssertTrue(sawBlink)
    }

    func testOnlyOneSpecialActionAtATimeAndSleepyWakesUpSurprised() {
        // 난수를 최대값으로 고정하면 특수 동작 후보 중 마지막(졸기)이 선택된다.
        let b = brain(random: { 0.999 })
        _ = b.update(now: 12.0, gaze: .center)             // 눈 깜빡임
        let picked = b.update(now: 12.4, gaze: .center)    // 특수 동작 선택
        XCTAssertEqual(picked.state, .sleepy)
        XCTAssertGreaterThan(picked.pose.sleepZ, -1)

        // 졸고 있는 동안에는 다른 동작으로 바뀌지 않는다.
        XCTAssertEqual(b.update(now: 14.0, gaze: Gaze(x: 2, y: 0, isNear: true, horizontal: 1)).state, .sleepy)
        // 다 졸고 나면 화들짝 깬다.
        XCTAssertEqual(b.update(now: 17.0, gaze: .center).state, .surprised)
    }

    func testTypingWakesTheCharacterUp() {
        let b = brain(random: { 0.999 })
        _ = b.update(now: 12.0, gaze: .center)
        XCTAssertEqual(b.update(now: 12.4, gaze: .center).state, .sleepy)
        b.registerKeystroke(at: 13.0)
        XCTAssertEqual(b.update(now: 13.05, gaze: .center).state, .surprised)
    }

    func testSleepyOnlyAfterLongIdle() {
        let b = brain(random: { 0.999 })
        b.registerKeystroke(at: 11.9)     // 방금 타자를 쳤으므로 졸 리 없다
        _ = b.update(now: 12.0, gaze: .center)
        let picked = b.update(now: 13.6, gaze: .center)
        XCTAssertNotEqual(picked.state, .sleepy)
    }

    func testKeystrokeAPICarriesNoKeyContent() {
        // registerKeystroke 는 시각만 받는다. 키 내용이 들어올 통로 자체가 없다.
        let b = brain()
        b.registerKeystroke(at: 3.0)
        XCTAssertEqual(b.secondsSinceLastKey(at: 4.0) ?? -1, 1.0, accuracy: 0.0001)
    }
}
