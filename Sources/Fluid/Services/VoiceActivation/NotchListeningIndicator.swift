import Foundation

/// Real "listening" indicator for Tier C idle wake-word listening, backed by the
/// existing notch overlay surface. Presents a passive, persistent "listening" state
/// that is distinct from the active-recording overlay, so a false wake is obvious.
@MainActor
final class NotchListeningIndicator: ListeningIndicating {
    func showListening() {
        // Passive idle state — does NOT start the audio-level publisher (we are not
        // recording; only the ANE VAD is running while idle).
        NotchOverlayManager.shared.showListeningIndicator()
    }

    func hideListening() {
        NotchOverlayManager.shared.hideListeningIndicator()
    }
}
