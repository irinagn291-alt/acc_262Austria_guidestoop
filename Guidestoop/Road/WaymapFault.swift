import Foundation

/// Role: Road. Faults the graph can raise. Views never invent a second error vocabulary.
enum WaymapFault: Error, Equatable, Sendable {
    case alreadyStakedToday
    case blankChore
    case negativeValue
    case ridgeShut
    case ridgeSpent
}
