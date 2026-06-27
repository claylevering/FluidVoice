import Foundation

/// Tier A — ends an active recording when the VAD reports sustained silence,
/// with an always-on hard-cap timer as the independent safety net.
/// Pure logic: time and the stop action are injected, so it is fully unit-testable.
@MainActor
final class AutoStopController {
    private let scheduler: CapScheduler
    private let stop: () -> Void

    private var capToken: Cancellable2?
    private var isActive = false   // true between recordingDidStart and the first stop

    init(scheduler: CapScheduler, stop: @escaping () -> Void) {
        self.scheduler = scheduler
        self.stop = stop
    }

    func recordingDidStart(capSeconds: Int) {
        self.isActive = true
        self.capToken?.cancel()
        self.capToken = self.scheduler.schedule(after: TimeInterval(capSeconds)) { [weak self] in
            guard let self, self.isActive else { return }
            self.fireStop()
        }
    }

    func handle(_ event: SpeechActivityEvent) {
        guard self.isActive else { return }
        switch event {
        case .speechStarted:
            break
        case .speechEnded:
            self.fireStop()
        }
    }

    func recordingDidStop() {
        self.isActive = false
        self.capToken?.cancel()
        self.capToken = nil
    }

    private func fireStop() {
        guard self.isActive else { return }
        self.isActive = false
        self.capToken?.cancel()
        self.capToken = nil
        self.stop()
    }
}
