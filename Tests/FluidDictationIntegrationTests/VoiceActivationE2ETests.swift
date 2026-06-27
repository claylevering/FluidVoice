@testable import FluidVoice_Debug
import AVFoundation
import Foundation
import XCTest

@MainActor
final class VoiceActivationE2ETests: XCTestCase {
    #if arch(arm64)
    func testWakePhraseDetectedInFixture() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RUN_MODEL_TESTS"] == "1",
            "Set RUN_MODEL_TESTS=1 to run the model-bearing wake-word E2E (downloads CtcModels).")
        guard let url = Bundle(for: Self.self).url(
            forResource: "wake_then_speech", withExtension: "wav") else {
            throw XCTSkip(
                "Fixture wake_then_speech.wav not present. Record a 16kHz mono clip of " +
                "the wake phrase + a sentence + ~2s silence, add it to the " +
                "FluidDictationIntegrationTests target resources, and re-run with RUN_MODEL_TESTS=1.")
        }
        let samples = try Self.load16kMono(url)
        let detector = CtcWakeWordDetector(phrase: "Hey Fluid")
        let hit = await detector.detect(in: samples)
        XCTAssertTrue(hit, "Wake phrase should be detected in the fixture")
    }

    private static func load16kMono(_ url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let buf = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length))!
        try file.read(into: buf)
        guard let ch = buf.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: ch, count: Int(buf.frameLength)))
    }
    #endif
}
