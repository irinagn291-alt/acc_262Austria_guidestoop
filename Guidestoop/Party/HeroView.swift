import SwiftUI

/// Role: Party. Hero sheet. Level, total XP, weekly ridge. Level is never stored.
@MainActor
struct HeroView: View {
    var watch: WaymapWatch
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize

    init(watch: WaymapWatch) {
        self.watch = watch
    }

    init() {
        self.init(watch: WaymapFixture.populated())
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            heroBody(now: timeline.date)
        }
        .background(MoorVellum.Palette.background.ignoresSafeArea())
    }

    private func heroBody(now: Date) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            VellumSheetBar(title: "Hero", closeLabel: "Close hero") {
                dismiss()
            }
            if watch.persistFailed {
                errorState
            } else if watch.graph.stakes.isEmpty {
                VellumVacancy(
                    image: "gds_EmptyList",
                    headline: "The party is untried.",
                    line: "Stake the cairn to earn XP. Level is one plus total XP over one hundred.",
                    actionTitle: "Back to the waymap"
                ) {
                    dismiss()
                }
            } else {
                populated(now: now)
            }
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func populated(now: Date) -> some View {
        let party = watch.graph.party
        let ridge = watch.graph.ridge(at: now, calendar: watch.calendar)
        let fork = watch.graph.revealedFork(at: now, calendar: watch.calendar)
        let camp = WaymapAtlas.camp(id: watch.graph.walker.occupiedCampID)?.title ?? "this cairn"
        let days = watch.graph.campStreak(at: now, calendar: watch.calendar)
        let planted = plantedStakes(now: now)
        let slots = ridgeSlots(ridge: ridge, planted: planted, fork: fork, now: now)
        return VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            partyBand(party: party, days: days, camp: camp)
            Text(jobTitle(fork: fork, ridge: ridge, now: now))
                .font(MoorVellum.Step.title.font)
                .foregroundStyle(MoorVellum.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(jobLine(ridge: ridge, planted: planted.count, days: days, camp: camp, fork: fork))
                .font(MoorVellum.Step.body.font)
                .foregroundStyle(MoorVellum.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            ridgeRow(ridge: ridge, slots: slots, planted: planted.count, now: now)
            mechanic(fork: fork, now: now)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: hSize == .regular ? 240 : 168)
            primaryVerb(ridge: ridge, camp: camp, fork: fork, now: now)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func partyBand(party: PartyMark, days: Int, camp: String) -> some View {
        let into = party.totalXP % 100
        return VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: MoorVellum.space(2)) {
                figure(WaymapFigures.count(party.level), "level")
                figure(WaymapFigures.count(party.totalXP), "XP")
                figure(WaymapFigures.count(days), "days here")
            }
            Text("\(WaymapFigures.count(days)) days at \(camp)")
                .font(MoorVellum.Step.body.font)
                .foregroundStyle(MoorVellum.Palette.background)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(MoorVellum.Palette.background.opacity(0.28))
                    Rectangle()
                        .fill(MoorVellum.Palette.accent)
                        .frame(width: max(6, geo.size.width * CGFloat(into) / 100))
                }
            }
            .frame(height: 10)
            .accessibilityLabel("\(WaymapFigures.count(into)) of 100 XP toward the next level")
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoorVellum.Palette.ink)
        .accessibilityElement(children: .contain)
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(MoorVellum.Step.display.font)
                .foregroundStyle(MoorVellum.Palette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(MoorVellum.Step.caption.font)
                .foregroundStyle(MoorVellum.Palette.background.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func ridgeRow(ridge: RidgeBoss, slots: [RidgeSlot], planted: Int, now: Date) -> some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
            HStack(alignment: .top, spacing: MoorVellum.space(1)) {
                ForEach(slots) { slot in
                    ridgeButton(slot, now: now)
                }
            }
            .frame(maxWidth: .infinity)
            Text("\(WaymapFigures.count(RidgeBoss.bonusXP)) bonus XP when five cairns stand this week")
                .font(MoorVellum.Step.caption.font)
                .foregroundStyle(MoorVellum.Palette.muted)
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoorVellum.Palette.surface)
        .overlay {
            Rectangle()
                .stroke(MoorVellum.Palette.ink, lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(planted) of 5 cairns this stand\(ridge.bonusClaimed ? ", bonus claimed" : "")"
        )
    }

    private func ridgeButton(_ slot: RidgeSlot, now: Date) -> some View {
        Button {
            tap(slot, now: now)
        } label: {
            VStack(spacing: MoorVellum.space(1)) {
                cairnMark(slot)
                    .frame(width: 44, height: 44)
                Text(slot.title)
                    .font(MoorVellum.Step.footnote.font)
                    .fontWeight(.semibold)
                    .foregroundStyle(slot.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(slot.mark)
                    .font(MoorVellum.Step.caption.font)
                    .foregroundStyle(slot.ink.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: MoorVellum.tap + 36)
            .padding(.vertical, MoorVellum.space(1))
            .background(slot.fill)
            .overlay {
                Rectangle()
                    .stroke(MoorVellum.Palette.ink, lineWidth: slot.kind == .today ? 2 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slot.title), \(slot.mark)")
        .accessibilityHint(slot.hint)
    }

    private func cairnMark(_ slot: RidgeSlot) -> some View {
        CairnPile()
            .fill(slot.cairnFill)
            .overlay {
                CairnPile().stroke(slot.cairnStroke, lineWidth: 2)
            }
    }

    @ViewBuilder
    private func mechanic(fork: ForkReveal?, now: Date) -> some View {
        if let fork {
            roadPick(fork)
        } else {
            CairnBoard(
                graph: watch.graph,
                now: now,
                calendar: watch.calendar,
                pan: .zero,
                scale: 1,
                walkerDrag: .zero,
                compact: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MoorVellum.Palette.surface)
            .overlay {
                Rectangle()
                    .stroke(MoorVellum.Palette.ink, lineWidth: 2)
            }
            .accessibilityHidden(true)
        }
    }

    private func roadPick(_ fork: ForkReveal) -> some View {
        let regular = hSize == .regular
        return Group {
            if regular {
                HStack(alignment: .top, spacing: MoorVellum.space(1)) {
                    roadVerb(fork.left)
                    roadVerb(fork.right)
                }
            } else {
                VStack(spacing: MoorVellum.space(1)) {
                    roadVerb(fork.left)
                    roadVerb(fork.right)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func roadVerb(_ camp: Camp) -> some View {
        Button {
            Task { await watch.dragWalker(to: camp.id) }
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
                CairnPile()
                    .fill(MoorVellum.Palette.accent)
                    .overlay {
                        CairnPile().stroke(MoorVellum.Palette.background, lineWidth: 2)
                    }
                    .frame(width: 44, height: 44)
                Text(camp.title)
                    .font(hSize == .regular ? MoorVellum.Step.title.font : MoorVellum.Step.figure.font)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text("Take this road")
                    .font(MoorVellum.Step.body.font)
                    .foregroundStyle(MoorVellum.Palette.background.opacity(0.88))
            }
            .padding(MoorVellum.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: hSize == .regular ? 168 : 88)
            .background(MoorVellum.Palette.ink)
            .overlay {
                Rectangle()
                    .stroke(MoorVellum.Palette.ink, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(watch.busy)
        .accessibilityLabel("Take \(camp.title)")
        .accessibilityHint("Commits this road and seals the sibling")
    }

    @ViewBuilder
    private func primaryVerb(ridge: RidgeBoss, camp: String, fork: ForkReveal?, now: Date) -> some View {
        if ridge.isOpen {
            Button {
                Task { await watch.claimRidge(at: now) }
            } label: {
                verbLabel(watch.busy ? "Claiming…" : "Claim the ridge")
            }
            .buttonStyle(.plain)
            .disabled(watch.busy)
        } else if let fork {
            VStack(spacing: MoorVellum.space(1)) {
                liveRoad("Take \(fork.left.title)", campID: fork.left.id)
                liveRoad("Take \(fork.right.title)", campID: fork.right.id)
            }
        } else if watch.canStake(at: now) && !watch.busy {
            Button {
                Task { await watch.stake(at: now) }
                dismiss()
            } label: {
                verbLabel("Stake today's cairn")
            }
            .buttonStyle(.plain)
        } else {
            Button {
                watch.showCamp(watch.graph.walker.occupiedCampID)
                dismiss()
            } label: {
                verbLabel("Back to the waymap")
            }
            .buttonStyle(.plain)
        }
    }

    private func liveRoad(_ title: String, campID: String) -> some View {
        Button {
            Task { await watch.dragWalker(to: campID) }
            dismiss()
        } label: {
            Text(title)
                .font(MoorVellum.Step.body.font)
                .fontWeight(.semibold)
                .foregroundStyle(MoorVellum.Palette.background)
                .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                .background(MoorVellum.Palette.ink)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(watch.busy)
        .accessibilityLabel(title)
    }

    private func verbLabel(_ title: String) -> some View {
        Text(title)
            .font(MoorVellum.Step.body.font)
            .foregroundStyle(MoorVellum.Palette.background)
            .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
            .background(MoorVellum.Palette.accent)
            .contentShape(Rectangle())
    }

    private var errorState: some View {
        VellumVacancy(
            image: "gds_EmptyList",
            headline: "The hero mark failed to load.",
            line: "Retry the waymap. XP stays on this device.",
            actionTitle: "Retry"
        ) {
            Task { await watch.retryLoad() }
        }
    }

    private func jobTitle(fork: ForkReveal?, ridge: RidgeBoss, now: Date) -> String {
        if ridge.isOpen {
            return "Claim the ridge"
        }
        if fork != nil {
            return "Take one road"
        }
        if watch.canStake(at: now) {
            return "Stake today's cairn"
        }
        return "You stand at \(WaymapAtlas.camp(id: watch.graph.walker.occupiedCampID)?.title ?? "this cairn")"
    }

    private func jobLine(
        ridge: RidgeBoss,
        planted: Int,
        days: Int,
        camp: String,
        fork: ForkReveal?
    ) -> String {
        if ridge.bonusClaimed {
            return "This week's ridge bonus is claimed."
        }
        if ridge.isOpen {
            return "Five cairns opened the ridge. Claim \(WaymapFigures.count(RidgeBoss.bonusXP)) bonus XP."
        }
        if let fork {
            return "\(WaymapFigures.count(days)) cairns hold \(camp). Take \(fork.left.title) or \(fork.right.title)."
        }
        if planted == 0 {
            return "This week's ridge is open. Stake today's cairn to plant the first of five."
        }
        let remain = max(0, RidgeBoss.stakeGate - planted)
        return "\(WaymapFigures.count(planted)) of 5 cairns planted. \(WaymapFigures.count(remain)) more opens the claim."
    }

    private func ridgeSlots(
        ridge: RidgeBoss,
        planted: [CampStake],
        fork: ForkReveal?,
        now: Date
    ) -> [RidgeSlot] {
        let offerStake = fork == nil && watch.canStake(at: now) && !ridge.isOpen
        return (0..<RidgeBoss.stakeGate).map { index in
            if index < planted.count {
                let stake = planted[index]
                let title = WaymapAtlas.camp(id: stake.campID)?.title ?? stake.campID
                if ridge.bonusClaimed {
                    return RidgeSlot(id: index, kind: .claimed, title: title, campID: stake.campID)
                }
                return RidgeSlot(id: index, kind: .planted, title: title, campID: stake.campID)
            }
            if index == planted.count && offerStake {
                return RidgeSlot(id: index, kind: .today, title: "Today", campID: watch.graph.walker.occupiedCampID)
            }
            return RidgeSlot(id: index, kind: .later, title: "Cairn \(WaymapFigures.count(index + 1))", campID: nil)
        }
    }

    private func plantedStakes(now: Date) -> [CampStake] {
        let week = weekStakes(now: now)
        let stand = standStakes(now: now)
        if week.isEmpty { return Array(stand.prefix(RidgeBoss.stakeGate)) }
        if stand.count > week.count { return Array(stand.prefix(RidgeBoss.stakeGate)) }
        return Array(week.prefix(RidgeBoss.stakeGate))
    }

    private func weekStakes(now: Date) -> [CampStake] {
        let week = CairnDay.weekKey(for: now, calendar: watch.calendar)
        return watch.graph.stakes
            .filter { CairnDay.weekKey(for: $0.plantedAt, calendar: watch.calendar) == week }
            .sorted { $0.plantedAt < $1.plantedAt }
    }

    private func standStakes(now: Date) -> [CampStake] {
        let campID = watch.graph.walker.occupiedCampID
        let days = watch.graph.campStreak(at: now, calendar: watch.calendar)
        guard days > 0 else { return [] }
        return Array(
            watch.graph.stakes
                .filter { $0.campID == campID }
                .sorted { $0.plantedAt < $1.plantedAt }
                .suffix(days)
        )
    }

    private func tap(_ slot: RidgeSlot, now: Date) {
        switch slot.kind {
        case .today:
            Task { await watch.stake(at: now) }
            dismiss()
        case .later:
            dismiss()
        case .planted, .claimed:
            if let campID = slot.campID {
                watch.showCamp(campID)
            }
            dismiss()
        }
    }
}

private struct RidgeSlot: Identifiable {
    enum Kind {
        case planted
        case today
        case later
        case claimed
    }

    var id: Int
    var kind: Kind
    var title: String
    var campID: String?

    var mark: String {
        switch kind {
        case .planted: "planted"
        case .today: "stake here"
        case .later: "later"
        case .claimed: "claimed"
        }
    }

    var hint: String {
        switch kind {
        case .today: "Plants today's cairn and returns to the waymap"
        case .later: "Returns to the waymap"
        case .planted, .claimed: "Stands on this camp"
        }
    }

    var fill: Color {
        switch kind {
        case .today: MoorVellum.Palette.accent
        case .planted, .claimed: MoorVellum.Palette.ink
        case .later: MoorVellum.Palette.background
        }
    }

    var ink: Color {
        switch kind {
        case .today, .planted, .claimed: MoorVellum.Palette.background
        case .later: MoorVellum.Palette.ink
        }
    }

    var cairnFill: Color {
        switch kind {
        case .today: MoorVellum.Palette.background
        case .planted, .claimed: MoorVellum.Palette.accent
        case .later: MoorVellum.Palette.surface
        }
    }

    var cairnStroke: Color {
        switch kind {
        case .today: MoorVellum.Palette.ink
        case .planted, .claimed: MoorVellum.Palette.background
        case .later: MoorVellum.Palette.ink
        }
    }
}
