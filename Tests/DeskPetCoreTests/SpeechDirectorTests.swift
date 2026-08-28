import Foundation
import CoreGraphics
import TinyTest
import DeskPetCore

/// 고정된 난수열을 돌려주는 도우미.
private final class FakeRandom {
    private var values: [Double]
    private var index = 0
    init(_ values: [Double]) { self.values = values }
    func next() -> Double {
        defer { index += 1 }
        return values.isEmpty ? 0 : values[index % values.count]
    }
}

final class SpeechDirectorTests: XCTestCase {

    private func makeDirector() -> SpeechDirector {
        SpeechDirector(lines: SpeechLibrary.lines, tuning: SpeechLibrary.tuning)
    }

    func testNoBubbleBeforeIdleThreshold() {
        var director = makeDirector()
        let random = FakeRandom([0.0])
        for t in stride(from: 0.0, through: 170.0, by: 10.0) {
            XCTAssertNil(director.evaluate(now: t, idleSeconds: t, hour: 14, random: random.next))
        }
    }

    func testBubbleAppearsAfterThreeMinutesIdle() {
        var director = makeDirector()
        let random = FakeRandom([0.0])   // 항상 확률 통과, 첫 후보 선택
        XCTAssertNil(director.evaluate(now: 200, idleSeconds: 200, hour: 14, random: random.next))
        let bubble = director.evaluate(now: 221, idleSeconds: 221, hour: 14, random: random.next)
        XCTAssertNotNil(bubble)
        XCTAssertFalse(bubble!.text.isEmpty)
        XCTAssertGreaterThanOrEqual(bubble!.duration, 3)
        XCTAssertLessThanOrEqual(bubble!.duration, 5)
    }

    func testLowProbabilityKeepsBubblesRare() {
        var director = makeDirector()
        let random = FakeRandom([0.99])   // 확률 검사에서 항상 탈락
        var shown = 0
        for i in 0..<50 {
            let t = 200.0 + Double(i) * 21.0
            if director.evaluate(now: t, idleSeconds: t, hour: 14, random: random.next) != nil { shown += 1 }
        }
        XCTAssertEqual(shown, 0)
    }

    func testSameLineIsNotRepeatedWithinCooldown() {
        var director = makeDirector()
        var tuning = SpeechLibrary.tuning
        tuning.globalCooldown = 0
        director.tuning = tuning
        // 후보를 하나로 줄여 재사용 금지를 확인한다.
        director.lines = [SpeechLine(id: "only", text: "흠…", weight: 1)]
        let random = FakeRandom([0.0])

        XCTAssertNil(director.evaluate(now: 200, idleSeconds: 200, hour: 14, random: random.next))
        XCTAssertNotNil(director.evaluate(now: 221, idleSeconds: 221, hour: 14, random: random.next))
        // 15분이 지나기 전에는 같은 문구가 다시 나오지 않는다.
        XCTAssertNil(director.evaluate(now: 500, idleSeconds: 500, hour: 14, random: random.next))
        XCTAssertNotNil(director.evaluate(now: 1200, idleSeconds: 1200, hour: 14, random: random.next))
    }

    func testGlobalCooldownBetweenAnyTwoBubbles() {
        var director = makeDirector()
        let random = FakeRandom([0.0])
        _ = director.evaluate(now: 200, idleSeconds: 200, hour: 14, random: random.next)
        XCTAssertNotNil(director.evaluate(now: 221, idleSeconds: 221, hour: 14, random: random.next))
        XCTAssertNil(director.evaluate(now: 245, idleSeconds: 245, hour: 14, random: random.next))
    }

    func testLateNightLineOnlyAtNight() {
        let night = SpeechLibrary.lines.first { $0.id == "lateNight" }!
        XCTAssertEqual(night.hours, SpeechLibrary.lateNightHours)

        var day = SpeechDirector(lines: [night], tuning: SpeechLibrary.tuning)
        let random = FakeRandom([0.0])
        _ = day.evaluate(now: 200, idleSeconds: 200, hour: 14, random: random.next)
        XCTAssertNil(day.evaluate(now: 221, idleSeconds: 221, hour: 14, random: random.next))

        var lateNight = SpeechDirector(lines: [night], tuning: SpeechLibrary.tuning)
        let random2 = FakeRandom([0.0])
        _ = lateNight.evaluate(now: 200, idleSeconds: 200, hour: 1, random: random2.next)
        XCTAssertEqual(lateNight.evaluate(now: 221, idleSeconds: 221, hour: 1, random: random2.next)?.text,
                       "아직도 안 자?")
    }

    func testMealLinesOnlyAppearAtMealTimes() {
        let lunch = SpeechLibrary.lines.first { $0.text == "오늘 점심은?" }!
        let dinner = SpeechLibrary.lines.first { $0.text == "오늘 저녁은?" }!
        XCTAssertTrue(lunch.isAllowed(hour: 12))
        XCTAssertFalse(lunch.isAllowed(hour: 18))
        XCTAssertTrue(dinner.isAllowed(hour: 18))
        XCTAssertFalse(dinner.isAllowed(hour: 12))

        // 점심시간에 실제로 뽑히는지
        var director = SpeechDirector(lines: [lunch], tuning: SpeechFrequency.often.tuning)
        let random = FakeRandom([0.0])
        _ = director.evaluate(now: 100, idleSeconds: 100, hour: 12, random: random.next)
        XCTAssertEqual(director.evaluate(now: 112, idleSeconds: 112, hour: 12, random: random.next)?.text,
                       "오늘 점심은?")

        var offHours = SpeechDirector(lines: [lunch], tuning: SpeechFrequency.often.tuning)
        let random2 = FakeRandom([0.0])
        _ = offHours.evaluate(now: 100, idleSeconds: 100, hour: 22, random: random2.next)
        XCTAssertNil(offHours.evaluate(now: 112, idleSeconds: 112, hour: 22, random: random2.next))
    }

    func testAlwaysAvailableLinesHaveNoHourLimit() {
        let focus = SpeechLibrary.lines.first { $0.text == "집중해!" }!
        XCTAssertNil(focus.hours)
        for hour in 0...23 { XCTAssertTrue(focus.isAllowed(hour: hour)) }
    }

    func testDistractedLineIsTheRarest() {
        let distracted = SpeechLibrary.lines.first { $0.id == "distracted" }!
        let minOther = SpeechLibrary.lines.filter { $0.id != "distracted" }.map(\.weight).min()!
        XCTAssertLessThan(distracted.weight, minOther)
        XCTAssertEqual(distracted.text, "딴짓하니?")
    }

    func testActivityResetsTheCheckSchedule() {
        var director = makeDirector()
        let random = FakeRandom([0.0])
        XCTAssertNil(director.evaluate(now: 200, idleSeconds: 200, hour: 14, random: random.next))
        director.noteActivity()
        // 다시 처음부터 기다린다.
        XCTAssertNil(director.evaluate(now: 221, idleSeconds: 221, hour: 14, random: random.next))
        XCTAssertNotNil(director.evaluate(now: 242, idleSeconds: 242, hour: 14, random: random.next))
    }
}

final class SpeechFrequencyTests: XCTestCase {

    func testFrequencyPresetsGetChattierInOrder() {
        let rare = SpeechFrequency.rare.tuning
        let normal = SpeechFrequency.normal.tuning
        let often = SpeechFrequency.often.tuning
        XCTAssertGreaterThan(rare.idleThreshold, normal.idleThreshold)
        XCTAssertGreaterThan(normal.idleThreshold, often.idleThreshold)
        XCTAssertLessThan(rare.chancePerCheck, normal.chancePerCheck)
        XCTAssertLessThan(normal.chancePerCheck, often.chancePerCheck)
        XCTAssertGreaterThan(rare.globalCooldown, often.globalCooldown)
    }

    func testDefaultFrequencyShowsBubbleWithoutWaitingThreeMinutes() {
        var director = SpeechDirector(lines: SpeechLibrary.lines, tuning: SpeechFrequency.normal.tuning)
        let random = FakeRandom2([0.0])
        // 45초 쉬면 후보가 되고, 12초 뒤 검사에서 나온다.
        XCTAssertNil(director.evaluate(now: 50, idleSeconds: 50, hour: 14, random: random.next))
        XCTAssertNotNil(director.evaluate(now: 63, idleSeconds: 63, hour: 14, random: random.next))
    }

    func testRequestedChatLineExists() {
        XCTAssertTrue(SpeechLibrary.lines.contains { $0.text == "yup! happy to chat!" })
    }

    func testPokeRepliesHaveCooldownAndDoNotRepeat() {
        var director = SpeechDirector()
        let random = FakeRandom2([0.0])
        let first = director.poke(now: 100, random: random.next)
        XCTAssertNotNil(first)
        // 쿨다운 안에서는 다시 나오지 않는다.
        XCTAssertNil(director.poke(now: 102, random: random.next))
        let second = director.poke(now: 110, random: random.next)
        XCTAssertNotNil(second)
        XCTAssertNotEqual(first?.lineID, second?.lineID)   // 같은 말 연속 금지
    }

    func testPokeIsSometimesSilent() {
        var director = SpeechDirector()
        let random = FakeRandom2([0.99])   // 확률 검사 탈락
        XCTAssertNil(director.poke(now: 100, random: random.next))
    }

    func testPokeBubbleIsShort() {
        var director = SpeechDirector()
        let random = FakeRandom2([0.0])
        XCTAssertEqual(director.poke(now: 100, random: random.next)?.duration, SpeechLibrary.pokeDuration)
        XCTAssertLessThan(SpeechLibrary.pokeDuration, 3.0)
    }
}

private final class FakeRandom2 {
    private var values: [Double]
    private var index = 0
    init(_ values: [Double]) { self.values = values }
    func next() -> Double {
        defer { index += 1 }
        return values.isEmpty ? 0 : values[index % values.count]
    }
}
