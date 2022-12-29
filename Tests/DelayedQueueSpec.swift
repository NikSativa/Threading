import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick
@testable import NQueue
@testable import NQueueTestHelpers

final class DelayedQueueSpec: QuickSpec {
    override func spec() {
        describe("DelayedQueue") {
            var subject: DelayedQueue!

            describe("fake queue") {
                describe("absent") {
                    beforeEach {
                        subject = .absent
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        it("should call task immediately") {
                            var didCall = false
                            subject.fire {
                                didCall = true
                            }
                            expect(didCall).to(beTrue())
                        }
                    }

                    context("when calling sync") {
                        it("should call task immediately") {
                            var didCall = false
                            subject.fire {
                                didCall = true
                            }
                            expect(didCall).to(beTrue())
                        }
                    }
                }

                describe("sync") {
                    var queue: FakeQueueable!

                    beforeEach {
                        queue = .init()
                        subject = .sync(queue)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        var didCall: Bool!

                        beforeEach {
                            didCall = false
                            queue.shouldFireSyncClosures = true
                            queue.stub(.sync).andReturn()
                            subject.fire {
                                didCall = true
                            }
                        }

                        it("should schedule task") {
                            expect(queue).to(haveReceived(.sync, countSpecifier: .exactly(1)))
                        }

                        it("should call task immediately") {
                            expect(didCall).to(beTrue())
                        }
                    }
                }

                describe("async") {
                    var queue: FakeQueueable!

                    beforeEach {
                        queue = .init()
                        subject = .async(queue)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        var didCall: Bool!

                        beforeEach {
                            didCall = false
                            queue.stub(.async).andReturn()
                            subject.fire {
                                didCall = true
                            }
                        }

                        it("should schedule task") {
                            expect(didCall).to(beFalse())
                            expect(queue).to(haveReceived(.async, with: Argument.anything, countSpecifier: .exactly(1)))
                        }

                        context("when the task is executed") {
                            beforeEach {
                                queue.asyncWorkItem?()
                            }

                            it("should call task immediately") {
                                expect(didCall).to(beTrue())
                            }
                        }
                    }
                }

                describe("async after") {
                    var queue: FakeQueueable!
                    var deadline: DispatchTime!

                    beforeEach {
                        deadline = .now() + .seconds(1)
                        queue = .init()
                        subject = .asyncAfter(deadline: deadline, queue: queue)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        var didCall: Bool!

                        beforeEach {
                            didCall = false
                            queue.stub(.asyncAfter).andReturn()
                            subject.fire {
                                didCall = true
                            }
                        }

                        it("should schedule task") {
                            expect(didCall).to(beFalse())
                            expect(queue).to(haveReceived(.asyncAfter, with: deadline, Argument.anything, countSpecifier: .exactly(1)))
                        }

                        context("when the task is executed") {
                            beforeEach {
                                queue.asyncWorkItem?()
                            }

                            it("should call task immediately") {
                                expect(didCall).to(beTrue())
                            }
                        }
                    }
                }
            }

            describe("real queue") {
                describe("absent") {
                    beforeEach {
                        subject = .absent
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should execute task immediately") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beTrue())
                    }
                }

                describe("sync") {
                    beforeEach {
                        subject = .sync(Queue.default)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should execute task immediately") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beTrue())
                    }
                }

                describe("async") {
                    beforeEach {
                        subject = .async(Queue.default)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should schedule task") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beFalse())
                        expect(didCall).toEventually(beTrue(), timeout: .seconds(2))
                    }
                }
            }
        }
    }
}
