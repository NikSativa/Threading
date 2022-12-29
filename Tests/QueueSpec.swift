import Foundation
import Nimble
import NQueue
import NQueueTestHelpers
import NSpry
import Quick

final class QueueSpec: QuickSpec {
    override func spec() {
        describe("Queue") {
            var subject: Queueable!

            beforeEach {
                subject = Queue.main
            }

            it("should not be nil") {
                expect(subject).toNot(beNil())
            }

            describe("async") {
                var didCall = false

                beforeEach {
                    subject.async {
                        didCall = true
                    }
                }

                afterEach {
                    didCall = false
                }

                it("should not call task") {
                    expect(didCall).toNot(beTrue())
                }

                it("should call task") {
                    expect(didCall).toEventually(beTrue())
                }
            }

            describe("asyncAfter") {
                var didCall = false

                beforeEach {
                    subject.asyncAfter(deadline: .now() + .seconds(1)) {
                        didCall = true
                    }
                }

                afterEach {
                    didCall = false
                }

                it("should not call task") {
                    expect(didCall).toNot(beTrue())
                }

                it("should call task") {
                    expect(didCall).toEventually(beTrue(), timeout: .seconds(2))
                }
            }

            describe("sync") {
                var didCall = false

                beforeEach {
                    subject.sync {
                        didCall = true
                    }
                }

                it("should call task") {
                    expect(didCall).to(beTrue())
                }
            }
        }
    }
}
