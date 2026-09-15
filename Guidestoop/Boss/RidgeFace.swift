import SwiftUI

/// Role: Boss. Weekly ridge overlay on Map. Not a destination.
@MainActor
struct RidgeFace: View {
    var mark: RidgeBoss
    var busy: Bool
    var onClaim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
            Text("Ridge")
                .vellumText(.title)
            Text("Five stakes opened the week. Claim bonus XP.")
                .vellumText(.body)
            HStack {
                Text(WaymapFigures.count(RidgeBoss.bonusXP))
                    .vellumText(.figure)
                    .layoutPriority(1)
                Text("bonus XP")
                    .vellumText(.caption)
                    .foregroundStyle(MoorVellum.Palette.muted)
            }
            Button(action: onClaim) {
                Text(busy ? "Claiming…" : "Claim the ridge")
                    .vellumText(.body)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(busy)
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity)
        .background(MoorVellum.Palette.surface)
        .overlay {
            Rectangle()
                .stroke(MoorVellum.Palette.ink, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ridge bonus, \(WaymapFigures.count(RidgeBoss.bonusXP)) XP")
    }
}
