import SwiftUI
import UIKit

/// Role: Road. Moorland tokens. Hex and SF Pro live only here. Views never hard-code either.
enum MoorVellum {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#EDE6D4"
        static let surface = "#D8CFBC"
        static let ink = "#1E1914"
        static let accent = "#33501F"
        static let danger = "#6B2418"
        static let muted = "#565046"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("accent")
        static let danger = Color(red: 107 / 255, green: 36 / 255, blue: 24 / 255)
        static let muted = Color("muted")
    }

    enum Step: CaseIterable {
        case display
        case title
        case body
        case caption
        case figure
        case footnote

        var font: Font {
            switch self {
            case .display: .system(.title).weight(.semibold)
            case .title: .system(.title2).weight(.semibold)
            case .body: .system(.body)
            case .caption: .system(.caption)
            case .figure: .system(.title3).weight(.semibold)
            case .footnote: .system(.footnote)
            }
        }
    }

    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let readable: CGFloat = 640
    static let radius: CGFloat = 0
    static let motion: Animation = .easeInOut(duration: 0.28)

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }

    static func art(_ name: String) -> Image? {
        UIImage(named: name) == nil ? nil : Image(name)
    }

    static func faultCopy(_ fault: WaymapFault) -> String {
        switch fault {
        case .alreadyStakedToday: "This day's cairn already holds a stake."
        case .blankChore: "Name the chore before it can be planted."
        case .negativeValue: "A stake cannot take value."
        case .ridgeShut: "The ridge stays shut until five stakes this week."
        case .ridgeSpent: "This week's ridge bonus is already claimed."
        }
    }

    static func warningCopy(_ warning: WaymapWarning) -> String {
        switch warning {
        case .recoveredFromBackup: "The waymap was recovered from a backup."
        case .startedEmpty: "The waymap could not be read and started empty."
        }
    }

    static func veilCopy(_ veil: CampVeil) -> String {
        switch veil {
        case .fogged: "fogged"
        case .revealed: "revealed"
        case .occupied: "occupied"
        case .committed: "committed"
        case .sealed: "sealed"
        }
    }
}

/// Role: Road. Catalog art when the later pass lands; a Path cairn otherwise.
struct CairnPile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let base = rect.height * 0.22
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.08, y: rect.maxY - base * 1.6, width: rect.width * 0.84, height: base * 1.4))
        path.addEllipse(in: CGRect(x: midX - rect.width * 0.28, y: rect.midY - base * 0.2, width: rect.width * 0.56, height: base * 1.2))
        path.addEllipse(in: CGRect(x: midX - rect.width * 0.16, y: rect.minY + base * 0.2, width: rect.width * 0.32, height: base))
        return path
    }
}

/// Role: Road. Full-page vacancy: art, headline, line, one full-width CTA.
struct VellumVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: MoorVellum.space(2)) {
            Group {
                if let art = MoorVellum.art(image) {
                    art
                        .resizable()
                        .scaledToFit()
                } else {
                    CairnPile()
                        .stroke(MoorVellum.Palette.ink, lineWidth: 2)
                }
            }
            .frame(width: MoorVellum.space(14), height: MoorVellum.space(14))
            .accessibilityHidden(true)
            Text(headline)
                .vellumText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .vellumText(.body)
                .foregroundStyle(MoorVellum.Palette.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button(action: action) {
                Text(actionTitle)
                    .vellumText(.body)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Role: Road. Sheet header. Close chrome is the whole 44pt label.
struct VellumSheetBar: View {
    var title: String
    var closeLabel: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: MoorVellum.space(1)) {
            Text(title)
                .vellumText(.title)
                .lineLimit(1)
            Spacer(minLength: MoorVellum.space(1))
            Button(action: onClose) {
                Text("Close")
                    .vellumText(.body)
                    .foregroundStyle(MoorVellum.Palette.accent)
                    .padding(.horizontal, MoorVellum.space(1))
                    .frame(minWidth: MoorVellum.tap, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(closeLabel)
        }
    }
}

extension View {
    func vellumText(_ step: MoorVellum.Step) -> some View {
        font(step.font)
            .foregroundStyle(MoorVellum.Palette.ink)
    }

    func vellumHit() -> some View {
        frame(minWidth: MoorVellum.tap, minHeight: MoorVellum.tap)
            .contentShape(Rectangle())
    }

    func vellumColumn() -> some View {
        modifier(VellumColumn())
    }
}

private struct VellumColumn: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: hSize == .regular ? 860 : MoorVellum.readable)
            .frame(maxWidth: .infinity)
    }
}
