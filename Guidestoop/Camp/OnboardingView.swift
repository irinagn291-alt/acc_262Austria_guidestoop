import SwiftUI

/// Role: Camp. One-shot cover. Skip still writes defaults. Re-runnable from Settings.
@MainActor
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(onFinish: @escaping () -> Void = {}) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: MoorVellum.space(2)) {
            Group {
                switch page {
                case 0:
                    pageBody(
                        image: "gds_Onboarding1",
                        title: "Stake the cairn",
                        line: "Stand on the occupied camp. One chore a day plants a stake. A second stake the same day is refused."
                    )
                case 1:
                    pageBody(
                        image: "gds_Onboarding2",
                        title: "Hold the streak",
                        line: "Yesterday must hold a stake or the streak drops. Three days on this camp opens the gate."
                    )
                case 2:
                    pageBody(
                        image: "gds_Onboarding3",
                        title: "Drag one road",
                        line: "The gate sprouts two forward camps. A further stake does not pick. Drag the walker onto one cairn."
                    )
                default:
                    pageBody(
                        image: "gds_TwistHero",
                        title: "The sibling seals",
                        line: "That drag writes the chosen edge and seals the other for this map. Five stakes in a week open the ridge."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : MoorVellum.motion, value: page)
            VStack(spacing: MoorVellum.space(1)) {
                Button {
                    if page < 3 {
                        page += 1
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < 3 ? "Next" : "Open the waymap")
                        .vellumText(.body)
                        .foregroundStyle(MoorVellum.Palette.background)
                        .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                        .background(MoorVellum.Palette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    onFinish()
                } label: {
                    Text("Skip")
                        .vellumText(.body)
                        .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                        .background(MoorVellum.Palette.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MoorVellum.Palette.background.ignoresSafeArea())
    }

    private func pageBody(image: String, title: String, line: String) -> some View {
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
            .frame(maxHeight: 280)
            .accessibilityHidden(true)
            Text(title)
                .vellumText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .vellumText(.body)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
    }
}
