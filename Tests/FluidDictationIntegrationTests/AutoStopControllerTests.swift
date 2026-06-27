@testable import FluidVoice_Debug
import Foundation
import XCTest

private final class FakeCancellable: Cancellable2 {
    private(set) var cancelled = false
    func cancel() { cancelled = true }
}

private final class FakeScheduler: CapScheduler {
    var lastDelay: TimeInterval?
    var lastWork: (() -> Void)?
    private(set) var tokens: [FakeCancellable] = []
    func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable2 {
        lastDelay = seconds
        lastWork = work
        let t = FakeCancellable()
        tokens.append(t)
        return t
    }
    func fireCap() { lastWork?() }
}

@MainActor
final class AutoStopControllerTests: XCTestCase {
    func testSpeechEndedTriggersStopOnce() {
        var stops = 0
        let sched = FakeScheduler()
        let c = AutoStopController(scheduler: sched, stop: { stops += 1 })
        c.recordingDidStart(capSeconds: 60)

        c.handle(.speechStarted)
        XCTAssertEqual(stops, 0)
        c.handle(.speechEnded(samples: []))
        XCTAssertEqual(stops, 1)
        c.handle(.speechEnded(samples: []))   // late event ignored
        XCTAssertEqual(stops, 1)
    }

    func testHardCapArmsWithConfiguredSecondsAndStops() {
        var stops = 0
        let sched = FakeScheduler()
        let c = AutoStopController(scheduler: sched, stop: { stops += 1 })
        c.recordingDidStart(capSeconds: 45)
        XCTAssertEqual(sched.lastDelay, 45)
        sched.fireCap()
        XCTAssertEqual(stops, 1)
    }

    func testSpeechEndCancelsTheCapTimer() {
        let sched = FakeScheduler()
        let c = AutoStopController(scheduler: sched, stop: {})
        c.recordingDidStart(capSeconds: 60)
        c.handle(.speechEnded(samples: []))
        XCTAssertTrue(sched.tokens.first?.cancelled ?? false)
    }

    func testCapDoesNotDoubleStopAfterSpeechEnd() {
        var stops = 0
        let sched = FakeScheduler()
        let c = AutoStopController(scheduler: sched, stop: { stops += 1 })
        c.recordingDidStart(capSeconds: 60)
        c.handle(.speechEnded(samples: []))
        sched.fireCap()   // stale cap fire must be ignored
        XCTAssertEqual(stops, 1)
    }
}
