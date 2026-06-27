import Foundation
#if arch(arm64)
import AVFoundation
import FluidAudio

/// Real `SpeechActivityStream` backed by FluidAudio's streaming Silero VAD.
/// Caller pushes 16kHz mono samples via `ingest(_:)`; events arrive on the handler.
/// VAD model is downloaded/loaded lazily on `start()` (same pattern as AsrModels/CtcModels).
///
/// Two feeding modes:
/// - `capturesOwnInput == false` (default): caller pushes samples (Tier A — ASRService
///   pumps the recording engine's buffers into `ingest(_:)`). No engine is owned here.
/// - `capturesOwnInput == true` (Tier C idle listening): this stream owns a private
///   `AVAudioEngine`, taps the mic, converts each buffer to 16kHz mono via FluidAudio's
///   `AudioConverter`, and feeds the VAD itself — there is no recording pipeline while idle.
final class VadSpeechActivityStream: SpeechActivityStream {
    private var manager: VadManager?
    private var streamState: VadStreamState?
    private var segmentBuffer: [Float] = []          // accumulates current speech segment
    private var handler: ((SpeechActivityEvent) -> Void)?
    private let segConfig: VadSegmentationConfig

    /// When true, this stream owns its own mic tap (Tier C idle listening).
    private let capturesOwnInput: Bool
    /// Private idle-capture engine; non-nil only while `capturesOwnInput` and started.
    private var engine: AVAudioEngine?
    /// Stateless FluidAudio converter → 16kHz mono Float32 (same one VadManager uses internally).
    private let converter = AudioConverter()

    /// - Parameters:
    ///   - hangoverSeconds: maps to VadSegmentationConfig.minSilenceDuration.
    ///   - capturesOwnInput: if true, owns an AVAudioEngine mic tap and self-feeds the VAD.
    ///     Default false keeps Tier A's push-only behavior unchanged.
    init(hangoverSeconds: TimeInterval, capturesOwnInput: Bool = false) {
        self.segConfig = VadSegmentationConfig(minSilenceDuration: hangoverSeconds)
        self.capturesOwnInput = capturesOwnInput
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
        if self.capturesOwnInput {
            try self.startIdleCapture()
        }
    }

    func stop() async {
        if self.capturesOwnInput {
            self.stopIdleCapture()
        }
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

    // MARK: - Idle mic capture (Tier C only)

    /// Install a mic tap on a private engine and drive the VAD from its buffers.
    /// MUST only be reached when `capturesOwnInput == true`. The engine must NOT
    /// run concurrently with ASRService's recording engine — the composition root
    /// pauses (stops) this stream before any recording engine starts.
    private func startIdleCapture() throws {
        guard self.engine == nil else { return }   // idempotent — never stack two taps
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let samples: [Float]
            do {
                samples = try self.converter.resampleBuffer(buffer)
            } catch {
                DebugLogger.shared.error("Idle VAD resample failed: \(error)", source: "VadSpeechActivityStream")
                return
            }
            guard samples.isEmpty == false else { return }
            Task { await self.ingest(samples) }
        }
        try engine.start()
        self.engine = engine
        DebugLogger.shared.info("Tier C idle mic tap started", source: "VadSpeechActivityStream")
    }

    /// Remove the tap and tear down the idle engine. After this returns the engine
    /// is not running, so the recording engine is free to claim the input device.
    private func stopIdleCapture() {
        guard let engine = self.engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
        DebugLogger.shared.info("Tier C idle mic tap stopped", source: "VadSpeechActivityStream")
    }
}
#endif
