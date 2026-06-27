import Foundation

/// Abstracts the "listening" indicator so Tier C orchestration is testable.
protocol ListeningIndicating: AnyObject {
    func showListening()
    func hideListening()
}
