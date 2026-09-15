import Foundation

/// Role: Seal. In-memory seam for fixtures and presentation tests. Never a second graph.
actor WaymapMemory: WaymapStoring {
    private var latest: WaymapGraph
    private var warning: WaymapWarning?

    init(graph: WaymapGraph = .empty, warning: WaymapWarning? = nil) {
        self.latest = graph
        self.warning = warning
    }

    func load() async -> (graph: WaymapGraph, warning: WaymapWarning?) {
        (latest, warning)
    }

    func graph() async -> WaymapGraph {
        latest
    }

    func stake(named: String?, value: Int?, at date: Date, calendar: Calendar) async throws -> WaymapGraph {
        latest = try latest.stake(named: named, value: value, at: date, calendar: calendar)
        return latest
    }

    func dragWalker(to campID: String, at date: Date, calendar: Calendar) async throws -> WaymapGraph {
        latest = latest.dragWalker(to: campID, at: date, calendar: calendar)
        return latest
    }

    func claimRidge(at date: Date, calendar: Calendar) async throws -> WaymapGraph {
        latest = try latest.claimRidge(at: date, calendar: calendar)
        return latest
    }

    func setOnboardingComplete(_ done: Bool) async throws -> WaymapGraph {
        latest = latest.settingOnboardingComplete(done)
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> WaymapGraph? {
        nil
    }
}
