import Foundation

/// Tier C — idle wake-word listening. On a VAD speech segment, runs the wake
/// detector; on a hit, calls the existing recording-start. Pauses while recording.
/// Pure orchestration: all I/O is injected, so it is fully unit-testable.
@MainActor
final class WakeActivationController {
    private let stream: SpeechActivityStream
    private let detector: WakeWordDetecting
    private let indicator: ListeningIndicating
    private let start: () async -> Void

    private var enabled = false
    private var recording = false

    init(stream: SpeechActivityStream,
         detector: WakeWordDetecting,
         indicator: ListeningIndicating,
         start: @escaping () async -> Void) {
        self.stream = stream
        self.detector = detector
        self.indicator = indicator
        self.start = start
        self.stream.setHandler { [weak self] event in
            Task { @MainActor in await self?.handle(event) }
        }
    }

    func enable() async {
        guard !self.enabled else { return }
        self.enabled = true
        self.recording = false
        await self.beginListening()
    }

    func disable() async {
        guard self.enabled else { return }
        self.enabled = false
        await self.stream.stop()
        self.indicator.hideListening()
    }

    func recordingDidStart() async {
        self.recording = true
        await self.stream.stop()   // don't listen for a wake while already recording
    }

    func recordingDidStop() async {
        self.recording = false
        if self.enabled { await self.beginListening() }
    }

    /// Test seam mirroring the stream handler.
    func handleForTesting(_ event: SpeechActivityEvent) async { await self.handle(event) }

    private func beginListening() async {
        do { try await self.stream.start() } catch {
            DebugLogger.shared.error("Wake listening start failed: \(error)", source: "WakeActivationController")
            return
        }
        self.indicator.showListening()
    }

    private func handle(_ event: SpeechActivityEvent) async {
        guard self.enabled, !self.recording else { return }
        guard case let .speechEnded(samples) = event else { return }
        if await self.detector.detect(in: samples) {
            // Block further wake triggers immediately; the composition root will
            // confirm via recordingDidStart() and resume via recordingDidStop().
            self.recording = true
            await self.start()
        }
    }
}
