import Dispatch
import Foundation
import NSpry
import XCTest

@testable import NQueue
@testable import NQueueTestHelpers

final class DispatchTime_QueueTests: XCTestCase {
    func test_seconds() {
        XCTAssertEqual(DispatchTimeInterval.seconds(2.2), .nanoseconds(22 * Int(1E+8)))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.2), .nanoseconds(2 * Int(1E+8)))
        XCTAssertEqual(DispatchTimeInterval.seconds(2), .nanoseconds(2 * Int(1E+9)))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.222222222), .nanoseconds(222222222))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.2222222223), .nanoseconds(222222222))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.2222222225), .nanoseconds(222222222))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.2222222228), .nanoseconds(222222222))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.222222222822), .nanoseconds(222222222))
        XCTAssertEqual(DispatchTimeInterval.seconds(0.222222222822), .nanoseconds(222222222))
    }

    func test_delayInSeconds() {
        XCTAssertEqual(DispatchTime.delayInSeconds(2.2), .now() + .nanoseconds(22 * Int(1E+8)))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.2), .now() + .nanoseconds(2 * Int(1E+8)))
        XCTAssertEqual(DispatchTime.delayInSeconds(2), .now() + .nanoseconds(2 * Int(1E+9)))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.222222222), .now() + .nanoseconds(222222222))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.2222222223), .now() + .nanoseconds(222222222))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.2222222225), .now() + .nanoseconds(222222222))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.2222222228), .now() + .nanoseconds(222222222))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.222222222822), .now() + .nanoseconds(222222222))
        XCTAssertEqual(DispatchTime.delayInSeconds(0.222222222822), .now() + .nanoseconds(222222222))
    }
}

private func XCTAssertEqual(_ expression1: @autoclosure () -> DispatchTime,
                            _ expression2: @autoclosure () -> DispatchTime,
                            _ message: @autoclosure () -> String = "",
                            file: StaticString = #filePath,
                            line: UInt = #line) {
    let lhs = Float(expression1().uptimeNanoseconds) / 1000
    let rhs = Float(expression2().uptimeNanoseconds) / 1000
    XCTAssertEqual(lhs, rhs, accuracy: 0.1, message(), file: file, line: line)
}
