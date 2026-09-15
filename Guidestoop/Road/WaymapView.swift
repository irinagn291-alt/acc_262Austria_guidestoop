import SwiftUI

/// Role: Road. Map root. Canvas + MagnifyGesture waymap. Journal, Hero, Settings arrive as sheets.
@MainActor
struct WaymapView: View {
    @Bindable var watch: WaymapWatch
    var handlesLaunch: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var pan: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var livePan: CGSize = .zero
    @State private var liveScale: CGFloat = 1
    @State private var walkerDrag: CGSize = .zero
    @State private var showSpinner = false

    init(watch: WaymapWatch, handlesLaunch: Bool = true) {
        self.watch = watch
        self.handlesLaunch = handlesLaunch
    }

    init() {
        self.init(watch: WaymapFixture.populated(), handlesLaunch: false)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            mapBody(now: timeline.date)
        }
        .background(MoorVellum.Palette.background.ignoresSafeArea())
        .background {
            Color.clear
                .fullScreenCover(item: $watch.sheet) { sheet in
                    sheetBody(sheet)
                }
        }
        .fullScreenCover(isPresented: $watch.showOnboarding) {
            OnboardingView {
                Task { await watch.finishOnboarding() }
            }
            .interactiveDismissDisabled()
        }
        .task {
            guard handlesLaunch else { return }
            await watch.bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
        }
        .onChange(of: watch.busy) { _, busy in
            if busy {
                Task {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    if watch.busy { showSpinner = true }
                }
            } else {
                showSpinner = false
            }
        }
        .onChange(of: watch.focusNonce) { _, _ in
            applyFocus()
        }
        .sensoryFeedback(.impact, trigger: watch.pulse)
    }

    @ViewBuilder
    private func sheetBody(_ sheet: WaymapSheet) -> some View {
        switch sheet {
        case .journal: JournalView(watch: watch)
        case .hero: HeroView(watch: watch)
        case .settings: SettingsView(watch: watch)
        case .fork: ForkSealView(watch: watch)
        }
    }

    private func mapBody(now: Date) -> some View {
        VStack(spacing: MoorVellum.space(1)) {
            headerBand
            header(now: now)
            if let warning = watch.warning, warning == .startedEmpty {
                errorBanner(MoorVellum.warningCopy(warning), now: now)
            } else if watch.persistFailed {
                errorBanner("The waymap could not be sealed.", now: now)
            } else if watch.graph.stakes.isEmpty {
                VellumVacancy(
                    image: "gds_EmptyHome",
                    headline: "The path is closed.",
                    line: "Finish three days to open the next node.",
                    actionTitle: "Stake today's cairn"
                ) {
                    Task { await watch.stake(at: now) }
                }
                .disabled(watch.busy || !watch.canStake(at: now))
            } else {
                populated(now: now)
            }
        }
        .overlay {
            if showSpinner {
                ProgressView()
                    .tint(MoorVellum.Palette.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MoorVellum.Palette.background.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func header(now: Date) -> some View {
        let camp = WaymapAtlas.camp(id: watch.graph.walker.occupiedCampID)?.title ?? "this cairn"
        let fork = watch.graph.revealedFork(at: now, calendar: watch.calendar)
        return VStack(alignment: .leading, spacing: MoorVellum.space(1)) {
            HStack(alignment: .top, spacing: MoorVellum.space(1)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(jobTitle(camp: camp, fork: fork, now: now))
                        .font(MoorVellum.Step.title.font)
                        .foregroundStyle(MoorVellum.Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    HStack(spacing: MoorVellum.space(2)) {
                        statPair(WaymapFigures.count(watch.graph.campStreak(at: now, calendar: watch.calendar)), "days")
                        statPair(WaymapFigures.count(watch.graph.party.level), "level")
                        Text(camp)
                            .font(MoorVellum.Step.caption.font)
                            .foregroundStyle(MoorVellum.Palette.muted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: MoorVellum.space(1))
                crumb("Journal", label: "Open journal") { watch.sheet = .journal }
                crumb("Hero", label: "Open hero") { watch.sheet = .hero }
                crumb("Settings", label: "Open settings") { watch.sheet = .settings }
            }
            .padding(.horizontal, MoorVellum.space(2))
            if let warning = watch.warning, warning == .recoveredFromBackup {
                Text(MoorVellum.warningCopy(warning))
                    .font(MoorVellum.Step.caption.font)
                    .foregroundStyle(MoorVellum.Palette.ink)
                    .padding(.horizontal, MoorVellum.space(2))
            }
        }
        .padding(.top, MoorVellum.space(1))
    }

    private var headerBand: some View {
        Rectangle()
            .fill(MoorVellum.Palette.ink)
            .frame(height: 3)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private func populated(now: Date) -> some View {
        let fork = watch.graph.revealedFork(at: now, calendar: watch.calendar)
        let ridge = watch.graph.ridge(at: now, calendar: watch.calendar)
        let scene = WaymapScene.focused(graph: watch.graph, now: now, calendar: watch.calendar)
        return VStack(spacing: MoorVellum.space(1)) {
            if let fault = watch.fault {
                Text(MoorVellum.faultCopy(fault))
                    .font(MoorVellum.Step.caption.font)
                    .foregroundStyle(MoorVellum.Palette.ink)
                    .padding(.horizontal, MoorVellum.space(2))
            }
            Text(jobLine(now: now, fork: fork))
                .font(MoorVellum.Step.body.font)
                .foregroundStyle(MoorVellum.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MoorVellum.space(2))
            GeometryReader { geo in
                let layout = layout(now: now, size: geo.size, scene: scene)
                ZStack {
                    CairnBoard(
                        graph: watch.graph,
                        now: now,
                        calendar: watch.calendar,
                        pan: CGSize(width: pan.width + livePan.width, height: pan.height + livePan.height),
                        scale: min(2, max(0.75, scale * liveScale)),
                        walkerDrag: walkerDrag,
                        drawsMarks: true
                    )
                    campMarks(now: now, layout: layout, scene: scene, fork: fork)
                    walkerHandle(now: now, layout: layout, fork: fork)
                    if ridge.isOpen {
                        VStack {
                            Spacer()
                            RidgeFace(mark: ridge, busy: watch.busy) {
                                Task { await watch.claimRidge(at: now) }
                            }
                            .padding(MoorVellum.space(2))
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .gesture(magnify)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : MoorVellum.motion, value: watch.graph.walker.occupiedCampID)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let fork {
                roadBar(fork: fork, now: now)
            } else if watch.canStake(at: now) && !watch.busy {
                liveVerb("Stake today's cairn") {
                    Task { await watch.stake(at: now) }
                }
                .padding(.horizontal, MoorVellum.space(2))
                .padding(.bottom, MoorVellum.space(2))
                .accessibilityHint("Plants this day's stake on the occupied camp")
            }
        }
    }

    private func jobTitle(camp: String, fork: ForkReveal?, now: Date) -> String {
        if fork != nil {
            return "Take one road"
        }
        if watch.canStake(at: now) {
            return "Stake today's cairn"
        }
        return "You stand at \(camp)"
    }

    private func jobLine(now: Date, fork: ForkReveal?) -> String {
        if let fork {
            return "Drag the walker onto \(fork.left.title) or \(fork.right.title). The other road seals."
        }
        if watch.canStake(at: now) {
            return "One chore on this camp. Three days open two roads."
        }
        return "Today's cairn holds. Three days on this camp open two roads."
    }

    private func campMarks(now: Date, layout: WaymapLayout, scene: WaymapScene, fork: ForkReveal?) -> some View {
        ForEach(WaymapAtlas.camps.filter { scene.campIDs.contains($0.id) }) { camp in
            let veil = watch.graph.veil(of: camp.id, at: now, calendar: watch.calendar)
            let point = layout.point(for: camp)
            Group {
                if veil == .revealed, fork != nil {
                    roadPlate(camp)
                } else {
                    standMark(camp, veil: veil)
                }
            }
            .position(x: point.x, y: point.y + plateLift(veil))
        }
    }

    private func roadPlate(_ camp: Camp) -> some View {
        Button {
            Task { await watch.dragWalker(to: camp.id) }
        } label: {
            VStack(spacing: 2) {
                Text(camp.title)
                    .font(hSize == .regular ? MoorVellum.Step.figure.font : MoorVellum.Step.body.font)
                    .fontWeight(.semibold)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text("Take this road")
                    .font(MoorVellum.Step.caption.font)
                    .foregroundStyle(MoorVellum.Palette.background)
                    .lineLimit(1)
            }
            .padding(.horizontal, MoorVellum.space(1))
            .frame(minWidth: hSize == .regular ? 200 : 148, minHeight: hSize == .regular ? 68 : 56)
            .background(MoorVellum.Palette.ink)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(watch.busy)
        .accessibilityLabel("Take \(camp.title)")
        .accessibilityHint("Commits this road and seals the sibling")
    }

    private func standMark(_ camp: Camp, veil: CampVeil) -> some View {
        VStack(spacing: 2) {
            Text(camp.title)
                .font(MoorVellum.Step.body.font)
                .fontWeight(.semibold)
                .foregroundStyle(MoorVellum.Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(standCaption(veil))
                .font(MoorVellum.Step.caption.font)
                .foregroundStyle(MoorVellum.Palette.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, MoorVellum.space(1))
        .frame(minWidth: 96)
        .accessibilityLabel("\(camp.title), \(MoorVellum.veilCopy(veil))")
    }

    private func standCaption(_ veil: CampVeil) -> String {
        switch veil {
        case .occupied: "you stand here"
        case .committed: "chosen"
        case .sealed: "sealed"
        case .fogged: "closed"
        case .revealed: "open"
        }
    }

    private func plateLift(_ veil: CampVeil) -> CGFloat {
        switch veil {
        case .occupied, .revealed: return hSize == .regular ? 56 : 48
        case .committed, .sealed, .fogged: return hSize == .regular ? 40 : 34
        }
    }

    private func walkerHandle(now: Date, layout: WaymapLayout, fork: ForkReveal?) -> some View {
        let camp = WaymapAtlas.camp(id: watch.graph.walker.occupiedCampID)
        let point = camp.map { layout.point(for: $0) } ?? .zero
        return VStack(spacing: 0) {
            Circle()
                .fill(Color.clear)
                .frame(width: MoorVellum.tap + 8, height: MoorVellum.tap + 8)
                .contentShape(Circle())
            if fork != nil {
                Text("drag")
                    .font(MoorVellum.Step.caption.font)
                    .fontWeight(.semibold)
                    .foregroundStyle(MoorVellum.Palette.ink)
            }
        }
        .contentShape(Rectangle())
        .position(x: point.x + walkerDrag.width, y: point.y + walkerDrag.height - 22)
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { walkerDrag = $0.translation }
                .onEnded { value in
                    let drop = CGPoint(x: point.x + value.translation.width, y: point.y + value.translation.height)
                    if let hit = layout.camp(at: drop),
                       watch.graph.revealedFork(at: now, calendar: watch.calendar)?.contains(hit.id) == true {
                        Task { await watch.dragWalker(to: hit.id, at: now) }
                    }
                    walkerDrag = .zero
                }
        )
        .accessibilityLabel("Walker")
        .accessibilityHint("Drag onto a revealed camp to seal the sibling road")
    }

    private func roadBar(fork: ForkReveal, now: Date) -> some View {
        VStack(spacing: MoorVellum.space(1)) {
            liveVerb("Take \(fork.left.title)") {
                Task { await watch.dragWalker(to: fork.left.id, at: now) }
            }
            liveVerb("Take \(fork.right.title)") {
                Task { await watch.dragWalker(to: fork.right.id, at: now) }
            }
        }
        .padding(.horizontal, MoorVellum.space(2))
        .padding(.bottom, MoorVellum.space(2))
    }

    private func liveVerb(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    private func layout(now: Date, size: CGSize, scene: WaymapScene) -> WaymapLayout {
        WaymapLayout(
            size: size,
            pan: CGSize(width: pan.width + livePan.width, height: pan.height + livePan.height),
            scale: min(2, max(0.75, scale * liveScale)),
            scene: scene
        )
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                liveScale = value.magnification
                livePan = CGSize(
                    width: value.startLocation.x * (1 - value.magnification) * 0.2,
                    height: value.startLocation.y * (1 - value.magnification) * 0.2
                )
            }
            .onEnded { value in
                scale = min(2, max(0.75, scale * value.magnification))
                pan = CGSize(width: pan.width + livePan.width, height: pan.height + livePan.height)
                liveScale = 1
                livePan = .zero
            }
    }

    private func statPair(_ value: String, _ caption: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(MoorVellum.Step.figure.font)
                .foregroundStyle(MoorVellum.Palette.ink)
            Text(caption)
                .font(MoorVellum.Step.caption.font)
                .foregroundStyle(MoorVellum.Palette.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private func crumb(_ title: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MoorVellum.Step.caption.font)
                .foregroundStyle(MoorVellum.Palette.ink)
                .padding(.horizontal, MoorVellum.space(1))
                .frame(minWidth: MoorVellum.tap, minHeight: MoorVellum.tap)
                .background(MoorVellum.Palette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func errorBanner(_ text: String, now: Date) -> some View {
        VStack(spacing: MoorVellum.space(2)) {
            Text(text)
                .font(MoorVellum.Step.body.font)
                .foregroundStyle(MoorVellum.Palette.ink)
                .multilineTextAlignment(.center)
            liveVerb("Retry") {
                Task { await watch.retryLoad(now: now) }
            }
        }
        .padding(MoorVellum.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func applyFocus() {
        guard let campID = watch.focusedCampID,
              let camp = WaymapAtlas.camp(id: campID)
        else { return }
        let scene = WaymapScene.focused(graph: watch.graph, now: Date(), calendar: watch.calendar)
        let layout = WaymapLayout(
            size: CGSize(width: 390, height: 520),
            pan: .zero,
            scale: min(2, max(0.75, scale)),
            scene: scene
        )
        pan = layout.centeringPan(for: camp)
    }
}
