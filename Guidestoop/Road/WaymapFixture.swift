import Foundation

/// Role: Road. Demo watches for no-argument screens. Not a persistence path.
enum WaymapFixture {
    @MainActor
    static func populated(now: Date = Date(), calendar: Calendar = .current) -> WaymapWatch {
        let graph = WaymapSeed.graph(now: now, calendar: calendar)
        return WaymapWatch(
            store: WaymapMemory(graph: graph),
            graph: graph,
            shouldLoad: false,
            calendar: calendar
        )
    }

    @MainActor
    static func vacant(calendar: Calendar = .current) -> WaymapWatch {
        let graph = WaymapGraph.empty.settingOnboardingComplete(true)
        return WaymapWatch(
            store: WaymapMemory(graph: graph),
            graph: graph,
            shouldLoad: false,
            calendar: calendar
        )
    }

    @MainActor
    static func committed(now: Date = Date(), calendar: Calendar = .current) -> WaymapWatch {
        let graph = WaymapSeed.graph(now: now, calendar: calendar)
        return WaymapWatch(
            store: WaymapMemory(graph: graph),
            graph: graph,
            shouldLoad: false,
            calendar: calendar
        )
    }

    @MainActor
    static func faulted(calendar: Calendar = .current) -> WaymapWatch {
        let graph = WaymapGraph.empty.settingOnboardingComplete(true)
        return WaymapWatch(
            store: WaymapMemory(graph: graph, warning: .startedEmpty),
            graph: graph,
            warning: .startedEmpty,
            shouldLoad: false,
            calendar: calendar
        )
    }
}
