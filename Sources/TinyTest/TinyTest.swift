import Foundation
import ObjectiveC

// ─────────────────────────────────────────────────────────────
//  아주 작은 테스트 러너.
//  Xcode 없이 Command Line Tools 만 있는 환경에서는 XCTest 를 쓸 수 없어서
//  같은 사용법(XCTestCase + XCTAssert*)을 그대로 흉내 낸 러너를 직접 넣었다.
//  실행:  swift run DeskPetTests
// ─────────────────────────────────────────────────────────────

@objcMembers
open class XCTestCase: NSObject {
    public required override init() { super.init() }
    open func setUp() {}
    open func tearDown() {}
}

public struct TestFailure {
    public let message: String
    public let file: String
    public let line: UInt
}

public enum TinyTest {
    nonisolated(unsafe) static var failures: [TestFailure] = []
    nonisolated(unsafe) static var assertionCount = 0

    static func record(_ message: String, _ file: StaticString, _ line: UInt) {
        let name = URL(fileURLWithPath: "\(file)").lastPathComponent
        failures.append(TestFailure(message: message, file: name, line: line))
    }

    /// 모든 XCTestCase 하위 클래스의 test... 메서드를 찾아 실행한다.
    public static func runAll() -> Int32 {
        var totalTests = 0
        var failedTests = 0
        var suites: [(AnyClass, [Selector])] = []

        // 우리 실행 파일 안에 있는 클래스만 훑는다(시스템 클래스는 건드리지 않는다).
        var classCount: UInt32 = 0
        var candidates: [AnyClass] = []
        if let image = class_getImageName(XCTestCase.self),
           let names = objc_copyClassNamesForImage(image, &classCount) {
            defer { free(UnsafeMutableRawPointer(names)) }
            for i in 0..<Int(classCount) {
                let name = String(cString: names[i])
                guard let cls = NSClassFromString(name) else { continue }
                candidates.append(cls)
            }
        }

        for cls in candidates {
            guard class_getSuperclass(cls) === XCTestCase.self else { continue }
            var methodCount: UInt32 = 0
            guard let methods = class_copyMethodList(cls, &methodCount) else { continue }
            defer { free(methods) }
            var selectors: [Selector] = []
            for j in 0..<Int(methodCount) {
                let sel = method_getName(methods[j])
                let name = NSStringFromSelector(sel)
                if name.hasPrefix("test") && !name.contains(":") { selectors.append(sel) }
            }
            if !selectors.isEmpty {
                selectors.sort { NSStringFromSelector($0) < NSStringFromSelector($1) }
                suites.append((cls, selectors))
            }
        }
        suites.sort { NSStringFromClass($0.0) < NSStringFromClass($1.0) }

        let start = Date()
        for (cls, selectors) in suites {
            print("\n▸ \(NSStringFromClass(cls))")
            for sel in selectors {
                guard let type = cls as? XCTestCase.Type else { continue }
                let instance = type.init()
                failures.removeAll()
                totalTests += 1
                instance.setUp()
                instance.perform(sel)
                instance.tearDown()
                let name = NSStringFromSelector(sel)
                if failures.isEmpty {
                    print("  ✓ \(name)")
                } else {
                    failedTests += 1
                    print("  ✗ \(name)")
                    for f in failures { print("      \(f.file):\(f.line)  \(f.message)") }
                }
            }
        }

        let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
        print("\n────────────────────────────────────────")
        print("테스트 \(totalTests)개 · 실패 \(failedTests)개 · 단언 \(assertionCount)회 · \(elapsed)초")
        print(failedTests == 0 ? "모든 테스트 통과 ✅" : "실패한 테스트가 있습니다 ❌")
        return failedTests == 0 ? 0 : 1
    }
}

// MARK: - XCTest 와 같은 이름의 단언 함수들

private func check(_ condition: Bool, _ message: @autoclosure () -> String,
                   _ file: StaticString, _ line: UInt) {
    TinyTest.assertionCount += 1
    if !condition { TinyTest.record(message(), file, line) }
}

public func XCTAssert(_ condition: Bool, _ message: String = "",
                      file: StaticString = #file, line: UInt = #line) {
    check(condition, message.isEmpty ? "조건이 참이 아님" : message, file, line)
}

public func XCTAssertTrue(_ condition: Bool, _ message: String = "",
                          file: StaticString = #file, line: UInt = #line) {
    check(condition, message.isEmpty ? "true 가 아님" : message, file, line)
}

public func XCTAssertFalse(_ condition: Bool, _ message: String = "",
                           file: StaticString = #file, line: UInt = #line) {
    check(!condition, message.isEmpty ? "false 가 아님" : message, file, line)
}

public func XCTAssertNil(_ value: Any?, _ message: String = "",
                         file: StaticString = #file, line: UInt = #line) {
    check(value == nil, message.isEmpty ? "nil 이 아님: \(String(describing: value))" : message, file, line)
}

public func XCTAssertNotNil(_ value: Any?, _ message: String = "",
                            file: StaticString = #file, line: UInt = #line) {
    check(value != nil, message.isEmpty ? "nil 임" : message, file, line)
}

public func XCTAssertEqual<T: Equatable>(_ a: T?, _ b: T?, _ message: String = "",
                                         file: StaticString = #file, line: UInt = #line) {
    check(a == b, message.isEmpty ? "\(String(describing: a)) != \(String(describing: b))" : message, file, line)
}

public func XCTAssertNotEqual<T: Equatable>(_ a: T?, _ b: T?, _ message: String = "",
                                            file: StaticString = #file, line: UInt = #line) {
    check(a != b, message.isEmpty ? "두 값이 같음: \(String(describing: a))" : message, file, line)
}

public func XCTAssertEqual(_ a: Double, _ b: Double, accuracy: Double, _ message: String = "",
                           file: StaticString = #file, line: UInt = #line) {
    check(abs(a - b) <= accuracy, message.isEmpty ? "\(a) 와 \(b) 의 차이가 \(accuracy) 보다 큼" : message, file, line)
}

public func XCTAssertGreaterThan<T: Comparable>(_ a: T, _ b: T, _ message: String = "",
                                                file: StaticString = #file, line: UInt = #line) {
    check(a > b, message.isEmpty ? "\(a) 가 \(b) 보다 크지 않음" : message, file, line)
}

public func XCTAssertGreaterThanOrEqual<T: Comparable>(_ a: T, _ b: T, _ message: String = "",
                                                       file: StaticString = #file, line: UInt = #line) {
    check(a >= b, message.isEmpty ? "\(a) 가 \(b) 이상이 아님" : message, file, line)
}

public func XCTAssertLessThan<T: Comparable>(_ a: T, _ b: T, _ message: String = "",
                                             file: StaticString = #file, line: UInt = #line) {
    check(a < b, message.isEmpty ? "\(a) 가 \(b) 보다 작지 않음" : message, file, line)
}

public func XCTAssertLessThanOrEqual<T: Comparable>(_ a: T, _ b: T, _ message: String = "",
                                                    file: StaticString = #file, line: UInt = #line) {
    check(a <= b, message.isEmpty ? "\(a) 가 \(b) 이하가 아님" : message, file, line)
}

public func XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
    check(false, message.isEmpty ? "실패" : message, file, line)
}
