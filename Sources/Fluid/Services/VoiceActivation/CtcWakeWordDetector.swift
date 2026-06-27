import Foundation

/// Arch-agnostic phrase rules (kept out of the #if so tests need no FluidAudio).
enum WakeWordPhrase {
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func validated(_ raw: String) -> String? {
        let n = normalized(raw)
        return n.count >= SettingsStore.minWakeWordLength ? n : nil
    }
}

#if arch(arm64)
import FluidAudio

/// Tier C wake-word detector. Lazily loads its own CtcModels (variant .ctc110m),
/// so it works regardless of the selected ASR backend (incl. Whisper). Heavy:
/// only call `detect` on VAD-gated speech segments, never continuously.
actor CtcWakeWordDetector: WakeWordDetecting {
    private var spotter: CtcKeywordSpotter?
    private var tokenizer: CtcTokenizer?
    private var vocabulary: CustomVocabularyContext?
    private var phrase: String

    /// Detection threshold; start from the library default and tune on-device.
    private let minScore: Float = ContextBiasingConstants.defaultMinSpotterScore

    init(phrase: String) {
        self.phrase = WakeWordPhrase.normalized(phrase)
    }

    private func ensureLoaded() async throws {
        if self.spotter == nil {
            let models = try await CtcModels.downloadAndLoad(variant: .ctc110m)
            self.tokenizer = try await CtcTokenizer.load(
                from: CtcModels.defaultCacheDirectory(for: models.variant))
            self.spotter = CtcKeywordSpotter(models: models)
        }
        if self.vocabulary == nil { self.rebuildVocabulary() }
    }

    private func rebuildVocabulary() {
        guard let tokenizer, let valid = WakeWordPhrase.validated(self.phrase) else {
            self.vocabulary = nil
            return
        }
        let tokens = tokenizer.encode(valid)
        guard !tokens.isEmpty else { self.vocabulary = nil; return }
        let term = CustomVocabularyTerm(
            text: valid, weight: 1.0, aliases: [], tokenIds: nil, ctcTokenIds: tokens)
        self.vocabulary = CustomVocabularyContext(
            terms: [term],
            alpha: 2.8,
            minCtcScore: -2.2,
            minSimilarity: 0.72,
            minCombinedConfidence: 0.64,
            minTermLength: 3
        )
    }

    nonisolated func updatePhrase(_ phrase: String) async {
        await self.setPhrase(phrase)
    }
    private func setPhrase(_ phrase: String) {
        self.phrase = WakeWordPhrase.normalized(phrase)
        self.vocabulary = nil   // force rebuild on next detect
    }

    nonisolated func detect(in samples: [Float]) async -> Bool {
        await self.detectInternal(samples)
    }
    private func detectInternal(_ samples: [Float]) async -> Bool {
        do {
            try await self.ensureLoaded()
            guard let spotter, let vocabulary else { return false }
            let result = try await spotter.spotKeywordsWithLogProbs(
                audioSamples: samples, customVocabulary: vocabulary, minScore: self.minScore)
            return result.detections.isEmpty == false
        } catch {
            DebugLogger.shared.error("Wake detect failed: \(error)", source: "CtcWakeWordDetector")
            return false
        }
    }
}
#endif
