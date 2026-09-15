import Foundation

/// Role: Camp. A cairn on the waymap. Atlas owns the catalog; the graph never invents a camp.
struct Camp: Identifiable, Equatable, Sendable, Codable {
    var id: String
    var title: String
    var value: Int
    var east: Double
    var north: Double
}
