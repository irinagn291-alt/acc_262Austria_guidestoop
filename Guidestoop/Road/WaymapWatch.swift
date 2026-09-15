import Foundation

/// Role: Road. Sheet crumbs over the locked waymap. The path never leaves.
enum WaymapSheet: String, Identifiable, Equatable, Sendable {
    case journal
    case hero
    case settings
    case fork

    var id: String { rawValue }
}

/// Role: Road. ReviewScreen hook. Read once after onboarding; today stays on Map.
enum WaymapReview {
    static func sheet(from arguments: [String] = ProcessInfo.processInfo.arguments) -> WaymapSheet? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen"),
              arguments.indices.contains(index + 1)
        else { return nil }
        switch arguments[index + 1] {
        case "log": return .journal
        case "goals": return .hero
        default: return nil
        }
    }
}

/// Role: Road. Observable owner of one WaymapGraph. Views call methods; they never keep a forked copy.
@MainActor
@Observable
final class WaymapWatch {
    private(set) var graph: WaymapGraph
    private(set) var warning: WaymapWarning?
    private(set) var fault: WaymapFault?
    private(set) var persistFailed = false
    private(set) var busy = false
    private(set) var pulse = 0
    var sheet: WaymapSheet?
    var showOnboarding = false
    private(set) var focusedCampID: String?
    private(set) var focusNonce = 0

    @ObservationIgnored private let store: any WaymapStoring
    @ObservationIgnored private let shouldLoad: Bool
    @ObservationIgnored private var reviewConsumed = false
    @ObservationIgnored let calendar: Calendar

    init(
        store: any WaymapStoring,
        graph: WaymapGraph = .empty,
        warning: WaymapWarning? = nil,
        shouldLoad: Bool = true,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.graph = graph
        self.warning = warning
        self.shouldLoad = shouldLoad
        self.calendar = calendar
        showOnboarding = !graph.onboardingComplete
    }

    static func live() -> WaymapWatch {
        do {
            let root = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = root.appendingPathComponent("Guidestoop", isDirectory: true)
            return WaymapWatch(store: WaymapStore(directory: directory))
        } catch {
            let watch = WaymapWatch(store: WaymapMemory(), shouldLoad: false)
            watch.persistFailed = true
            return watch
        }
    }

    func canStake(at date: Date) -> Bool {
        let key = CairnDay.key(for: date, calendar: calendar)
        return !graph.stakes.contains { $0.dayKey == key }
    }

    func bootstrap(now: Date = Date()) async {
        guard shouldLoad else { return }
        busy = true
        defer { busy = false }
        persistFailed = false
        fault = nil
        let loaded = await store.load()
        graph = loaded.graph
        warning = loaded.warning
        do {
            if let seeded = try await store.seedDemoIfNeeded(now: now, calendar: calendar) {
                graph = seeded
            }
        } catch {
            persistFailed = true
        }
        showOnboarding = !graph.onboardingComplete
        if !showOnboarding {
            applyReview()
        }
    }

    func finishOnboarding() async {
        do {
            graph = try await store.setOnboardingComplete(true)
            persistFailed = false
            showOnboarding = false
            applyReview()
        } catch {
            persistFailed = true
        }
    }

    func stake(at date: Date = Date()) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            graph = try await store.stake(named: nil, value: nil, at: date, calendar: calendar)
            fault = nil
            persistFailed = false
            pulse += 1
        } catch let raised as WaymapFault {
            fault = raised
        } catch {
            persistFailed = true
        }
    }

    func dragWalker(to campID: String, at date: Date = Date()) async {
        do {
            let next = try await store.dragWalker(to: campID, at: date, calendar: calendar)
            guard next != graph else { return }
            graph = next
            fault = nil
            persistFailed = false
            pulse += 1
        } catch {
            persistFailed = true
        }
    }

    func claimRidge(at date: Date = Date()) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            graph = try await store.claimRidge(at: date, calendar: calendar)
            fault = nil
            persistFailed = false
            pulse += 1
        } catch let raised as WaymapFault {
            fault = raised
        } catch {
            persistFailed = true
        }
    }

    func flush() async {
        do {
            try await store.flush()
            persistFailed = false
        } catch {
            persistFailed = true
        }
    }

    func resetAllData() async {
        do {
            try await store.resetAllData()
            graph = .empty
            warning = nil
            fault = nil
            persistFailed = false
            showOnboarding = true
            sheet = nil
        } catch {
            persistFailed = true
        }
    }

    func reopenOnboarding() {
        sheet = nil
        showOnboarding = true
    }

    func applyReview() {
        guard !reviewConsumed else { return }
        reviewConsumed = true
        sheet = WaymapReview.sheet()
    }

    func retryLoad(now: Date = Date()) async {
        await bootstrap(now: now)
    }

    func showCamp(_ campID: String) {
        focusedCampID = campID
        focusNonce += 1
        sheet = nil
    }
}
