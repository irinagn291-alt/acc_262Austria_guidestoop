import Foundation

/// Role: Fork. Two forward cairns shown when the occupied-camp streak is at least three.
struct ForkReveal: Equatable, Sendable {
    var originCampID: String
    var left: Camp
    var right: Camp

    func contains(_ campID: String) -> Bool {
        left.id == campID || right.id == campID
    }

    func sibling(of campID: String) -> Camp? {
        if left.id == campID { return right }
        if right.id == campID { return left }
        return nil
    }
}

/// Role: Fork. Veil of a cairn. Colour is never the only signal — sealed also has a stroke in UI.
enum CampVeil: Equatable, Sendable {
    case fogged
    case revealed
    case occupied
    case committed
    case sealed
}
