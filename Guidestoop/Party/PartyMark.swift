import Foundation

/// Role: Party. Derived hero mark. level is never stored; it is 1 + totalXP / 100.
struct PartyMark: Equatable, Sendable {
    var totalXP: Int

    var level: Int { 1 + totalXP / 100 }
}
