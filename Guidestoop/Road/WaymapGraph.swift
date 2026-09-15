import Foundation

/// Role: Road. Single forking-path DAG. Camps are nodes, roads are directed edges.
/// Views call methods on this value and never keep a forked copy of the path.
struct WaymapGraph: Equatable, Sendable {
    var walker: Walker
    var stakes: [CampStake]
    var roads: [Road]
    var seals: [ForkSeal]
    var totalXP: Int
    var claimedRidgeWeeks: [Int]
    var chore: CampChore
    var onboardingComplete: Bool

    static let empty = WaymapGraph(
        walker: Walker(occupiedCampID: WaymapAtlas.gateID),
        stakes: [],
        roads: [],
        seals: [],
        totalXP: 0,
        claimedRidgeWeeks: [],
        chore: .cairn,
        onboardingComplete: false
    )

    var party: PartyMark { PartyMark(totalXP: totalXP) }

    var committedRoads: [Road] { roads.filter { !$0.isSealed } }

    var sealedRoads: [Road] { roads.filter(\.isSealed) }

    func settingOnboardingComplete(_ done: Bool) -> WaymapGraph {
        var next = self
        next.onboardingComplete = done
        return next
    }

    func settingChore(_ chore: CampChore) -> WaymapGraph {
        var next = self
        next.chore = chore
        return next
    }

    func partyStreak(at date: Date, calendar: Calendar) -> Int {
        Self.streak(in: stakes, at: date, calendar: calendar)
    }

    func campStreak(at date: Date, calendar: Calendar) -> Int {
        let here = stakes.filter { $0.campID == walker.occupiedCampID }
        return Self.streak(in: here, at: date, calendar: calendar)
    }

    func weekStakeCount(at date: Date, calendar: Calendar) -> Int {
        let week = CairnDay.weekKey(for: date, calendar: calendar)
        return stakes.filter { CairnDay.weekKey(for: $0.plantedAt, calendar: calendar) == week }.count
    }

    func ridge(at date: Date, calendar: Calendar) -> RidgeBoss {
        let week = CairnDay.weekKey(for: date, calendar: calendar)
        return RidgeBoss(
            weekKey: week,
            completions: weekStakeCount(at: date, calendar: calendar),
            bonusClaimed: claimedRidgeWeeks.contains(week)
        )
    }

    func revealedFork(at date: Date, calendar: Calendar) -> ForkReveal? {
        guard campStreak(at: date, calendar: calendar) >= 3 else { return nil }
        let origin = walker.occupiedCampID
        guard !seals.contains(where: { $0.originCampID == origin }) else { return nil }
        guard let pair = WaymapAtlas.pair(from: origin) else { return nil }
        return ForkReveal(originCampID: origin, left: pair.0, right: pair.1)
    }

    func isPathClosed(at date: Date, calendar: Calendar) -> Bool {
        revealedFork(at: date, calendar: calendar) == nil && committedRoads.isEmpty
    }

    func showsSeededWaymap(at date: Date, calendar: Calendar) -> Bool {
        onboardingComplete
            && revealedFork(at: date, calendar: calendar) != nil
            && !stakes.contains { $0.dayKey == CairnDay.key(for: date, calendar: calendar) }
    }

    func veil(of campID: String, at date: Date, calendar: Calendar) -> CampVeil {
        if walker.occupiedCampID == campID { return .occupied }
        if seals.contains(where: { $0.sealedCampID == campID }) { return .sealed }
        if committedRoads.contains(where: { $0.toCampID == campID || $0.fromCampID == campID }) {
            return .committed
        }
        if let fork = revealedFork(at: date, calendar: calendar), fork.contains(campID) {
            return .revealed
        }
        return .fogged
    }

    func stake(
        named choreName: String? = nil,
        value: Int? = nil,
        at date: Date,
        calendar: Calendar
    ) throws -> WaymapGraph {
        let name = (choreName ?? chore.name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw WaymapFault.blankChore }
        let award = value ?? WaymapAtlas.camp(id: walker.occupiedCampID)?.value ?? chore.value
        guard award >= 0 else { throw WaymapFault.negativeValue }
        let dayKey = CairnDay.key(for: date, calendar: calendar)
        guard !stakes.contains(where: { $0.dayKey == dayKey }) else {
            throw WaymapFault.alreadyStakedToday
        }
        var next = self
        next.stakes.append(
            CampStake(
                campID: walker.occupiedCampID,
                choreName: name,
                dayKey: dayKey,
                value: award,
                plantedAt: date
            )
        )
        next.totalXP += award
        next.chore = CampChore(name: name, value: award)
        return next
    }

    /// Drag writes one edge and seals the sibling. Fogged or sealed cairns are a no-op.
    func dragWalker(to campID: String, at date: Date, calendar: Calendar) -> WaymapGraph {
        guard let fork = revealedFork(at: date, calendar: calendar),
              fork.contains(campID),
              let sibling = fork.sibling(of: campID)
        else { return self }
        var next = self
        next.roads.append(
            Road(fromCampID: fork.originCampID, toCampID: campID, isSealed: false)
        )
        next.roads.append(
            Road(fromCampID: fork.originCampID, toCampID: sibling.id, isSealed: true)
        )
        next.seals.append(
            ForkSeal(
                originCampID: fork.originCampID,
                chosenCampID: campID,
                sealedCampID: sibling.id
            )
        )
        next.walker.occupiedCampID = campID
        return next
    }

    func claimRidge(at date: Date, calendar: Calendar) throws -> WaymapGraph {
        let mark = ridge(at: date, calendar: calendar)
        guard mark.completions >= RidgeBoss.stakeGate else { throw WaymapFault.ridgeShut }
        guard !mark.bonusClaimed else { throw WaymapFault.ridgeSpent }
        var next = self
        next.totalXP += RidgeBoss.bonusXP
        next.claimedRidgeWeeks.append(mark.weekKey)
        next.claimedRidgeWeeks.sort()
        return next
    }

    private static func streak(in stakes: [CampStake], at date: Date, calendar: Calendar) -> Int {
        let keys = Set(stakes.map(\.dayKey))
        let today = CairnDay.key(for: date, calendar: calendar)
        let start: Int
        if keys.contains(today) {
            start = today
        } else if let yest = CairnDay.previous(of: today, calendar: calendar), keys.contains(yest) {
            start = yest
        } else {
            return 0
        }
        var count = 0
        var cursor: Int? = start
        while let key = cursor, keys.contains(key) {
            count += 1
            cursor = CairnDay.previous(of: key, calendar: calendar)
        }
        return count
    }
}
