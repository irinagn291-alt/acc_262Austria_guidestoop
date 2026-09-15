import Foundation

/// Role: Road. Fixed cairn catalog and successor pairs. The graph looks up; it does not author camps.
enum WaymapAtlas {
    static let gateID = "stoop"

    static let camps: [Camp] = [
        Camp(id: "stoop", title: "Gate Stoop", value: 10, east: 0.50, north: 0.16),
        Camp(id: "knoll", title: "Moor Knoll", value: 12, east: 0.32, north: 0.46),
        Camp(id: "ford", title: "Peat Ford", value: 12, east: 0.68, north: 0.46),
        Camp(id: "stack", title: "Granite Stack", value: 15, east: 0.16, north: 0.80),
        Camp(id: "rise", title: "Lichen Rise", value: 15, east: 0.40, north: 0.86),
        Camp(id: "hollow", title: "Mist Hollow", value: 15, east: 0.60, north: 0.86),
        Camp(id: "gall", title: "Iron Gall", value: 15, east: 0.84, north: 0.80),
    ]

    static let pairIDs: [String: (String, String)] = [
        "stoop": ("knoll", "ford"),
        "knoll": ("stack", "rise"),
        "ford": ("hollow", "gall"),
    ]

    static func camp(id: String) -> Camp? {
        camps.first(where: { $0.id == id })
    }

    static func pair(from id: String) -> (Camp, Camp)? {
        guard let ids = pairIDs[id],
              let left = camp(id: ids.0),
              let right = camp(id: ids.1)
        else { return nil }
        return (left, right)
    }
}
