import Foundation

/// Role: Seal. Persistable fork-seal commit. One chosen road; the sibling stays sealed for this map.
struct ForkSeal: Equatable, Sendable, Codable {
    var originCampID: String
    var chosenCampID: String
    var sealedCampID: String
}
