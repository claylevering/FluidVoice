import Foundation

/// Arch-agnostic boundary event emitted by a speech-activity stream.
/// `.speechEnded` carries the just-completed segment's 16kHz mono samples
/// (used by the wake-word path; ignored by the endpointer).
enum SpeechActivityEvent: Equatable {
    case speechStarted
    case speechEnded(samples: [Float])
}
