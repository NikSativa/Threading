import Foundation
import Nimble
import NQueue
import NQueueTestHelpers
import NSpry
import Quick

final class DispatchTimeInterval_NQueueSpec: QuickSpec {
    override func spec() {
        describe("DispatchTimeInterval+NQueue") {
            it("should convert correctly") {
                expect(DispatchTimeInterval.seconds(2.2)) == .nanoseconds(22 * Int(1E+8))
                expect(DispatchTimeInterval.seconds(0.2)) == .nanoseconds(2 * Int(1E+8))
                expect(DispatchTimeInterval.seconds(2)) == .nanoseconds(2 * Int(1E+9))
                expect(DispatchTimeInterval.seconds(0.222222222)) == .nanoseconds(222222222)
                expect(DispatchTimeInterval.seconds(0.2222222223)) == .nanoseconds(222222222)
                expect(DispatchTimeInterval.seconds(0.2222222225)) == .nanoseconds(222222222)
                expect(DispatchTimeInterval.seconds(0.2222222228)) == .nanoseconds(222222222)
                expect(DispatchTimeInterval.seconds(0.222222222822)) == .nanoseconds(222222222)
                expect(DispatchTimeInterval.seconds(0.222222222822)) == .nanoseconds(222222222)
            }
        }
    }
}
