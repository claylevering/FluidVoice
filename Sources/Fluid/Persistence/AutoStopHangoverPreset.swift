import Foundation

enum AutoStopHangoverPreset: String, CaseIterable, Identifiable, Codable {
    case snappy
    case balanced
    case relaxed

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .snappy: return "Snappy"
        case .balanced: return "Balanced"
        case .relaxed: return "Relaxed"
        }
    }

    /// Maps to FluidAudio `VadSegmentationConfig.minSilenceDuration`.
    var silenceSeconds: TimeInterval {
        switch self {
        case .snappy: return 0.8
        case .balanced: return 1.2
        case .relaxed: return 1.8
        }
    }
}
