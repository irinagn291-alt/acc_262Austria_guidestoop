import Foundation

/// Role: Camp. Named daily work (Quest). Staking writes this name onto the occupied cairn.
struct CampChore: Equatable, Sendable, Codable {
    var name: String
    var value: Int

    static let cairn = CampChore(name: "Stake the cairn", value: 10)

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
