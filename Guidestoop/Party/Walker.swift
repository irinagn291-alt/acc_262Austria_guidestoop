import Foundation

/// Role: Party. The walker token (Avatar). Occupies exactly one camp; drag commits a road.
struct Walker: Equatable, Sendable, Codable {
    var occupiedCampID: String
}
