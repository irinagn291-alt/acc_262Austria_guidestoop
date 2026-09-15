import Foundation

/// Role: Boss. Weekly ridge (WeeklyBoss). Overlay on the waymap after five stakes; not a destination.
struct RidgeBoss: Equatable, Sendable {
    static let stakeGate = 5
    static let bonusXP = 50

    var weekKey: Int
    var completions: Int
    var bonusClaimed: Bool

    var isOpen: Bool { completions >= RidgeBoss.stakeGate && !bonusClaimed }
}
