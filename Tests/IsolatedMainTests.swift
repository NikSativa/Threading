import Foundation
import Threading
import XCTest

#if swift(>=6.0)
private struct MainActorOnly: Sendable {
    var value: Int = 1
}
#else
private struct MainActorOnly {
    var value: Int = 1
}
#endif

private enum MainActorError: Error {
    case someError
}

final class IsolatedMainTests: XCTestCase {
    func test_void() async {
        var notSendable: MainActorOnly = .init()

        await withCheckedContinuation { continuation in
            Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(notSendable.value, 1)
                notSendable.value += 1
                continuation.resume()
            }
        }

        Queue.isolatedMain.sync {
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(notSendable.value, 2)
        }
    }

    func test_value() async {
        var notSendable: MainActorOnly = .init()

        let some = await withCheckedContinuation { continuation in
            Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(notSendable.value, 1)
                notSendable.value += 1
                continuation.resume(returning: notSendable.value)
            }
        }
        XCTAssertEqual(some, 2)

        let some2 = await withCheckedContinuation { continuation in
            Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(notSendable.value, 2)
                notSendable.value += 1
                continuation.resume(returning: notSendable.value)
            }
        }
        XCTAssertEqual(some2, 3)

        let some3 = Queue.isolatedMain.sync {
            XCTAssertTrue(Thread.isMainThread)
            notSendable.value += 1
            return notSendable.value
        }
        XCTAssertEqual(some3, 4)
    }

    func test_throws() async throws {
        var notSendable: MainActorOnly = .init()

        let some = try await withCheckedThrowingContinuation { continuation in
            Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(notSendable.value, 1)
                notSendable.value += 1
                continuation.resume(returning: notSendable.value)
            }
        }
        XCTAssertEqual(some, 2)

        let some2 = try await withCheckedThrowingContinuation { continuation in
            Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(notSendable.value, 2)
                notSendable.value += 1
                continuation.resume(returning: notSendable.value)
            }
        }
        XCTAssertEqual(some2, 3)

        let some3 = try Queue.isolatedMain.sync {
            XCTAssertTrue(Thread.isMainThread)
            if notSendable.value == -1 { // never happen
                throw MainActorError.someError
            }
            notSendable.value += 1
            return notSendable.value
        }
        XCTAssertEqual(some3, 4)

        do {
            let some: Int = try Queue.isolatedMain.sync {
                XCTAssertTrue(Thread.isMainThread)
                if notSendable.value == 4 {
                    throw MainActorError.someError
                }
                return notSendable.value // never happen
            }
            XCTAssertTrue(some == -1, "should never happen: some3")
        } catch {
            XCTAssertEqual(error as? MainActorError, MainActorError.someError)
        }
    }
}
