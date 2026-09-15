import SwiftUI

/// Role: Seal. Chosen-road journal. Breadcrumb of written edges, not a fork-commit surface.
@MainActor
struct JournalView: View {
    var watch: WaymapWatch
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize

    init(watch: WaymapWatch) {
        self.watch = watch
    }

    init() {
        self.init(watch: WaymapFixture.committed())
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            journalBody(now: timeline.date)
        }
        .background(MoorVellum.Palette.background.ignoresSafeArea())
    }

    private func journalBody(now: Date) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            VellumSheetBar(title: "Journal", closeLabel: "Close journal") {
                dismiss()
            }
            if watch.persistFailed {
                errorState
            } else if steps.isEmpty {
                emptyTrail
            } else {
                trail(now: now)
            }
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func trail(now: Date) -> some View {
        let fork = watch.graph.revealedFork(at: now, calendar: watch.calendar)
        return VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            Text(headline)
                .vellumText(.title)
                .fixedSize(horizontal: false, vertical: true)
            Text(line(fork: fork))
                .vellumText(.body)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: MoorVellum.space(2)) {
                ForEach(steps) { step in
                    sealBlock(step)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            primaryVerb(now: now, fork: fork)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func sealBlock(_ step: TrailStep) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
            Button {
                stand(on: step.originID)
            } label: {
                HStack(spacing: MoorVellum.space(1)) {
                    Text("From \(title(step.originID))")
                        .font(MoorVellum.Step.figure.font)
                        .foregroundStyle(MoorVellum.Palette.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: MoorVellum.space(1))
                    Text(watch.graph.walker.occupiedCampID == step.originID ? "you stand here" : "written camp")
                        .font(MoorVellum.Step.footnote.font)
                        .foregroundStyle(MoorVellum.Palette.muted)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: MoorVellum.tap, alignment: .leading)
                .padding(.horizontal, MoorVellum.space(2))
                .background(MoorVellum.Palette.surface)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("From \(title(step.originID))")
            .accessibilityHint("Stand on this camp")
            HStack(alignment: .top, spacing: MoorVellum.space(1)) {
                if let chosenID = step.chosenID {
                    campCard(
                        campID: chosenID,
                        mark: "chosen",
                        fill: MoorVellum.Palette.ink,
                        ink: MoorVellum.Palette.background,
                        sealed: false
                    )
                }
                if let sealedID = step.sealedID {
                    campCard(
                        campID: sealedID,
                        mark: "sealed",
                        fill: MoorVellum.Palette.surface,
                        ink: MoorVellum.Palette.ink,
                        sealed: true
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MoorVellum.space(2))
        .background(MoorVellum.Palette.surface)
        .overlay {
            Rectangle()
                .stroke(MoorVellum.Palette.ink, lineWidth: 2)
        }
    }

    private func campCard(
        campID: String,
        mark: String,
        fill: Color,
        ink: Color,
        sealed: Bool
    ) -> some View {
        let here = watch.graph.walker.occupiedCampID == campID
        return Button {
            stand(on: campID)
        } label: {
            VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
                Text(title(campID))
                    .font(hSize == .regular ? MoorVellum.Step.title.font : MoorVellum.Step.figure.font)
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(here ? "\(mark) · you stand here" : mark)
                    .font(MoorVellum.Step.body.font)
                    .foregroundStyle(ink.opacity(0.88))
                    .lineLimit(2)
            }
            .padding(MoorVellum.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: hSize == .regular ? 168 : 120)
            .background(fill)
            .overlay {
                Rectangle()
                    .stroke(MoorVellum.Palette.ink, lineWidth: sealed ? 2 : 1)
            }
            .overlay(alignment: .leading) {
                if sealed {
                    Rectangle()
                        .fill(MoorVellum.Palette.ink)
                        .frame(width: 3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title(campID)), \(mark) road")
        .accessibilityHint("Stand on this camp")
    }

    private func primaryVerb(now: Date, fork: ForkReveal?) -> some View {
        let label: String
        let action: () -> Void
        if fork != nil {
            label = "Back to the waymap"
            action = { dismiss() }
        } else if watch.canStake(at: now) && !watch.busy {
            label = "Stake today's cairn"
            action = {
                Task { await watch.stake(at: now) }
                dismiss()
            }
        } else {
            let camp = title(watch.graph.walker.occupiedCampID)
            label = "Stand at \(camp)"
            action = { stand(on: watch.graph.walker.occupiedCampID) }
        }
        return Button(action: action) {
            Text(label)
                .font(MoorVellum.Step.body.font)
                .foregroundStyle(MoorVellum.Palette.background)
                .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                .background(MoorVellum.Palette.accent)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var emptyTrail: some View {
        VellumVacancy(
            image: "gds_EmptyList",
            headline: "No road is written yet.",
            line: "Stake three days on this camp, then drag the walker onto one cairn.",
            actionTitle: "Back to the waymap"
        ) {
            dismiss()
        }
    }

    private var errorState: some View {
        VellumVacancy(
            image: "gds_EmptyList",
            headline: "The journal failed to load.",
            line: "Retry the waymap. Chosen roads stay on this device.",
            actionTitle: "Retry"
        ) {
            Task { await watch.retryLoad() }
        }
    }

    private var headline: String {
        if let last = watch.graph.seals.last {
            return "\(title(last.chosenCampID)) is the chosen road."
        }
        if let road = watch.graph.committedRoads.last {
            return "\(title(road.toCampID)) is the chosen road."
        }
        return "Chosen roads stay on this leaf."
    }

    private func line(fork: ForkReveal?) -> String {
        let sealedName: String
        if let last = watch.graph.seals.last {
            sealedName = title(last.sealedCampID)
        } else if let road = watch.graph.sealedRoads.last {
            sealedName = title(road.toCampID)
        } else {
            sealedName = "The other road"
        }
        if fork != nil {
            return "\(sealedName) is sealed. Drag the walker on the waymap to write the next road."
        }
        return "\(sealedName) is sealed. Stand on a written camp."
    }

    private var steps: [TrailStep] {
        if !watch.graph.seals.isEmpty {
            return watch.graph.seals.map { seal in
                TrailStep(
                    id: "\(seal.originCampID)-\(seal.chosenCampID)-\(seal.sealedCampID)",
                    originID: seal.originCampID,
                    chosenID: seal.chosenCampID,
                    sealedID: seal.sealedCampID
                )
            }
        }
        var byOrigin: [String: TrailStep] = [:]
        for road in watch.graph.roads {
            var step = byOrigin[road.fromCampID] ?? TrailStep(
                id: road.fromCampID,
                originID: road.fromCampID,
                chosenID: nil,
                sealedID: nil
            )
            if road.isSealed {
                step.sealedID = road.toCampID
            } else {
                step.chosenID = road.toCampID
            }
            byOrigin[road.fromCampID] = step
        }
        return Array(byOrigin.values)
    }

    private func stand(on campID: String) {
        watch.showCamp(campID)
        dismiss()
    }

    private func title(_ campID: String) -> String {
        WaymapAtlas.camp(id: campID)?.title ?? campID
    }
}

private struct TrailStep: Identifiable {
    var id: String
    var originID: String
    var chosenID: String?
    var sealedID: String?
}
