import Foundation

/// Decides whether a speech segment contains the configured wake phrase.
protocol WakeWordDetecting: AnyObject {
    func detect(in samples: [Float]) async -> Bool
    func updatePhrase(_ phrase: String) async
}
