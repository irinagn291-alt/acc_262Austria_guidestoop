import Foundation

/// Role: Road. A directed edge owned by WaymapGraph. A sealed sibling stays shut for this map.
struct Road: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var fromCampID: String
    var toCampID: String
    var isSealed: Bool

    init(
        id: UUID = UUID(),
        fromCampID: String,
        toCampID: String,
        isSealed: Bool
    ) {
        self.id = id
        self.fromCampID = fromCampID
        self.toCampID = toCampID
        self.isSealed = isSealed
    }
}
