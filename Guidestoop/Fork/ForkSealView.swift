import SwiftUI

/// Role: Fork. Twist screen. Streak reveals two roads; commit writes one edge and seals the other.
@MainActor
struct ForkSealView: View {
    var watch: WaymapWatch
    @Environment(\.dismiss) private var dismiss

    init(watch: WaymapWatch) {
        self.watch = watch
    }

    init() {
        self.init(watch: WaymapFixture.populated())
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            forkBody(now: timeline.date)
        }
        .background(MoorVellum.Palette.background.ignoresSafeArea())
    }

    private func forkBody(now: Date) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            VellumSheetBar(title: "Fork seal", closeLabel: "Close fork seal") {
                dismiss()
            }
            if watch.persistFailed {
                VellumVacancy(
                    image: "gds_TwistHero",
                    headline: "The fork could not be read.",
                    line: "Retry the waymap. A sealed sibling stays sealed.",
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retryLoad(now: now) }
                }
            } else if let fork = watch.graph.revealedFork(at: now, calendar: watch.calendar) {
                revealed(fork)
            } else if let seal = watch.graph.seals.last {
                sealed(seal)
            } else {
                VellumVacancy(
                    image: "gds_TwistHero",
                    headline: "The gate is shut.",
                    line: "Three days on the occupied camp sprouts two roads. A further stake does not pick.",
                    actionTitle: "Back to the waymap"
                ) {
                    dismiss()
                }
            }
        }
        .padding(MoorVellum.space(2))
        .vellumColumn()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func revealed(_ fork: ForkReveal) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            if let art = MoorVellum.art("gds_TwistHero") {
                art
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .accessibilityHidden(true)
            }
            Text("The gate is open")
                .vellumText(.title)
            Text("Drag the walker onto one cairn. That write commits the road and seals the sibling for this map.")
                .vellumText(.body)
            roadRow(title: fork.left.title, mark: "left road")
            roadRow(title: fork.right.title, mark: "right road")
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Text("Back to the waymap")
                    .vellumText(.body)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func sealed(_ seal: ForkSeal) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            Text("One road stands")
                .vellumText(.title)
            roadRow(title: title(seal.chosenCampID), mark: "chosen")
            roadRow(title: title(seal.sealedCampID), mark: "sealed")
            Text("Dragging toward the sealed cairn does nothing. The journal keeps this edge.")
                .vellumText(.body)
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Text("Back to the waymap")
                    .vellumText(.body)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func roadRow(title: String, mark: String) -> some View {
        HStack {
            Text(title)
                .vellumText(.body)
                .lineLimit(1)
            Spacer(minLength: MoorVellum.space(1))
            Text(mark)
                .vellumText(.caption)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
        .padding(.horizontal, MoorVellum.space(1))
        .background(MoorVellum.Palette.surface)
        .overlay(alignment: .leading) {
            if mark == "sealed" {
                Rectangle()
                    .fill(MoorVellum.Palette.ink)
                    .frame(width: 3)
            }
        }
        .accessibilityLabel("\(title), \(mark)")
    }

    private func title(_ campID: String) -> String {
        WaymapAtlas.camp(id: campID)?.title ?? campID
    }
}
