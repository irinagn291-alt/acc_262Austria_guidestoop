import Foundation

/// Role: Party. Display numbers. Round only here; stored XP stays exact.
enum WaymapFigures {
    static func count(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
