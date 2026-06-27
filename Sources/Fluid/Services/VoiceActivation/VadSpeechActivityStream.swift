import Foundation
#if arch(arm64)
import FluidAudio

/// Real `SpeechActivityStream` backed by FluidAudio's streaming Silero VAD.
/// Caller pushes 16kHz mono samples via `ingest(_:)`; events arrive on the handler.
/// VAD model is downloaded/loaded lazily on `start()` (same pattern as AsrModels/CtcModels).
final class VadSpeechActivityStream: SpeechActivityStream {
    private var manager: VadManager?
    private var streamState: VadStreamState?
    private var segmentBuffer: [Float] = []          // accumulates current speech segment
    private var handler: ((SpeechActivityEvent) -> Void)?
    private let segConfig: VadSegmentationConfig

    /// - Parameter hangoverSeconds: maps to VadSegmentationConfig.minSilenceDuration.
    init(hangoverSeconds: TimeInterval) {
        self.segConfig = VadSegmentationConfig(minSilenceDuration: hangoverSeconds)
    }

    func setHandler(_ handler: @escaping (SpeechActivityEvent) -> Void) {
        self.handler = handler
    }

    func start() async throws {
        await AudioStartupGate.shared.waitUntilOpen()
        if self.manager == nil {
            self.manager = try await VadManager(config: VadConfig())
        }
        self.streamState = await self.manager?.makeStreamState()
        self.segmentBuffer.removeAll(keepingCapacity: true)
    }

    func stop() async {
        self.streamState = nil
        self.segmentBuffer.removeAll(keepingCapacity: true)
    }

    /// Feed exactly VadManager.chunkSize (4096) samples at a time for best behavior;
    /// shorter trailing chunks are tolerated by the library.
    func ingest(_ samples16kMono: [Float]) async {
        guard let manager, var state = self.streamState else { return }
        self.segmentBuffer.append(contentsOf: samples16kMono)
        do {
            let result = try await manager.processStreamingChunk(
                samples16kMono, state: state, config: self.segConfig)
            state = result.state
            self.streamState = state
            if let event = result.event {
                switch event.kind {
                case .speechStart:
                    self.handler?(.speechStarted)
                case .speechEnd:
                    let segment = self.segmentBuffer
                    self.segmentBuffer.removeAll(keepingCapacity: true)
                    self.handler?(.speechEnded(samples: segment))
                }
            }
        } catch {
            DebugLogger.shared.error("VAD chunk failed: \(error)", source: "VadSpeechActivityStream")
        }
    }
}
#endif
