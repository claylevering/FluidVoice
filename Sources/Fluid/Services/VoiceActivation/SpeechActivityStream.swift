import Foundation

/// A source of speech start/end events over some audio input.
/// Real implementation wraps FluidAudio's streaming Silero VAD; tests inject a fake.
protocol SpeechActivityStream: AnyObject {
    func setHandler(_ handler: @escaping (SpeechActivityEvent) -> Void)
    func start() async throws
    func stop() async
}

/// Minimal cancel token for the hard-cap timer (named with a `2` suffix to avoid
/// clashing with Combine.Cancellable in files that import Combine).
protocol Cancellable2 {
    func cancel()
}

/// Test seam for the hard-cap timer so controller logic is unit-testable without real time.
protocol CapScheduler {
    func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable2
}

/// Production scheduler backed by DispatchQueue.main.
struct DispatchCapScheduler: CapScheduler {
    func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> Cancellable2 {
        let item = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
        return DispatchCancellable(item: item)
    }
}

private struct DispatchCancellable: Cancellable2 {
    let item: DispatchWorkItem
    func cancel() { item.cancel() }
}
