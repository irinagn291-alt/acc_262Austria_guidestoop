import Foundation

/// Role: Seal. Simulator-only occupied waymap. Device never seeds.
enum WaymapSeed {
    static let stakeA = uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1")
    static let stakeB = uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2")
    static let stakeC = uuid("cccccccc-cccc-4ccc-8ccc-ccccccccccc3")
    static let stakeD = uuid("dddddddd-dddd-4ddd-8ddd-ddddddddddd4")
    static let stakeE = uuid("eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee5")
    static let stakeF = uuid("ffffffff-ffff-4fff-8fff-fffffffffff6")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    /// Six days: three on the gate, one committed road, three on the occupied camp so two roads stand open. Today is free to stake.
    static func graph(now: Date, calendar: Calendar) -> WaymapGraph {
        let today = calendar.startOfDay(for: now)
        var graph = WaymapGraph.empty.settingOnboardingComplete(true)
        for (index, offset) in [-6, -5, -4].enumerated() {
            plant(&graph, id: [stakeA, stakeB, stakeC][index], offset: offset, today: today, calendar: calendar)
        }
        graph = committing(graph, origin: WaymapAtlas.gateID, chosen: "knoll", sealed: "ford")
        for (index, offset) in [-3, -2, -1].enumerated() {
            plant(&graph, id: [stakeD, stakeE, stakeF][index], offset: offset, today: today, calendar: calendar)
        }
        return graph
    }

    private static func plant(
        _ graph: inout WaymapGraph,
        id: UUID,
        offset: Int,
        today: Date,
        calendar: Calendar
    ) {
        let planted = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        let campID = graph.walker.occupiedCampID
        let award = WaymapAtlas.camp(id: campID)?.value ?? CampChore.cairn.value
        graph.stakes.append(
            CampStake(
                id: id,
                campID: campID,
                choreName: CampChore.cairn.name,
                dayKey: CairnDay.key(for: planted, calendar: calendar),
                value: award,
                plantedAt: planted
            )
        )
        graph.totalXP += award
    }

    private static func committing(
        _ graph: WaymapGraph,
        origin: String,
        chosen: String,
        sealed: String
    ) -> WaymapGraph {
        var next = graph
        next.roads.append(Road(fromCampID: origin, toCampID: chosen, isSealed: false))
        next.roads.append(Road(fromCampID: origin, toCampID: sealed, isSealed: true))
        next.seals.append(
            ForkSeal(originCampID: origin, chosenCampID: chosen, sealedCampID: sealed)
        )
        next.walker.occupiedCampID = chosen
        return next
    }
}
