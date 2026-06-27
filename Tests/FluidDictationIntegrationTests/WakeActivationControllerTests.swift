@testable import FluidVoice_Debug
import Foundation
import XCTest

private final class FakeStream: SpeechActivityStream {
    var started = 0, stopped = 0
    var handler: ((SpeechActivityEvent) -> Void)?
    func setHandler(_ handler: @escaping (SpeechActivityEvent) -> Void) { self.handler = handler }
    func start() async throws { started += 1 }
    func stop() async { stopped += 1 }
}
private final class FakeDetector: WakeWordDetecting {
    var result = false
    private(set) var calls = 0
    func detect(in samples: [Float]) async -> Bool { calls += 1; return result }
    func updatePhrase(_ phrase: String) async {}
}
private final class FakeIndicator: ListeningIndicating {
    var shown = 0, hidden = 0
    func showListening() { shown += 1 }
    func hideListening() { hidden += 1 }
}

@MainActor
final class WakeActivationControllerTests: XCTestCase {
    private func make() -> (WakeActivationController, FakeStream, FakeDetector, FakeIndicator, () -> Int) {
        let stream = FakeStream(); let detector = FakeDetector(); let indicator = FakeIndicator()
        var starts = 0
        let c = WakeActivationController(
            stream: stream, detector: detector, indicator: indicator,
            start: { starts += 1 })
        return (c, stream, detector, indicator, { starts })
    }

    func testEnableStartsListeningAndShowsIndicator() async {
        let (c, stream, _, indicator, _) = make()
        await c.enable()
        XCTAssertEqual(stream.started, 1)
        XCTAssertEqual(indicator.shown, 1)
    }

    func testWakeHitStartsRecording() async {
        let (c, _, detector, _, starts) = make()
        await c.enable()
        detector.result = true
        await c.handleForTesting(.speechEnded(samples: [0, 0, 0]))
        XCTAssertEqual(detector.calls, 1)
        XCTAssertEqual(starts(), 1)
    }

    func testNoWakeDoesNotStart() async {
        let (c, _, detector, _, starts) = make()
        await c.enable()
        detector.result = false
        await c.handleForTesting(.speechEnded(samples: [0]))
        XCTAssertEqual(starts(), 0)
    }

    func testListeningPausesDuringRecordingAndResumes() async {
        let (c, stream, _, _, _) = make()
        await c.enable()                       // started == 1
        await c.recordingDidStart()            // pause
        XCTAssertEqual(stream.stopped, 1)
        await c.recordingDidStop()             // resume
        XCTAssertEqual(stream.started, 2)
    }

    func testDisableStopsAndHides() async {
        let (c, stream, _, indicator, _) = make()
        await c.enable()
        await c.disable()
        XCTAssertEqual(stream.stopped, 1)
        XCTAssertEqual(indicator.hidden, 1)
    }
}
