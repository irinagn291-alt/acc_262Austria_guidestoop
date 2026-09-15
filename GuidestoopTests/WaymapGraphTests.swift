import XCTest
@testable import Guidestoop

final class WaymapGraphTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    func test_stake_emptyPopulatedInvalid() throws {
        var graph = WaymapGraph.empty
        XCTAssertTrue(graph.stakes.isEmpty)
        XCTAssertTrue(graph.isPathClosed(at: day(2026, 8, 24), calendar: calendar))

        graph = try graph.stake(named: "  Hold the cairn  ", at: day(2026, 8, 24), calendar: calendar)
        XCTAssertEqual(graph.stakes.count, 1)
        XCTAssertEqual(graph.stakes.first?.choreName, "Hold the cairn")
        XCTAssertEqual(graph.stakes.first?.dayKey, 20260824)
        XCTAssertEqual(graph.stakes.first?.campID, WaymapAtlas.gateID)

        XCTAssertThrowsError(try graph.stake(named: "   ", at: day(2026, 8, 25), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .blankChore)
        }
        XCTAssertThrowsError(try graph.stake(value: -1, at: day(2026, 8, 25), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .negativeValue)
        }
        XCTAssertThrowsError(try graph.stake(at: day(2026, 8, 24, hour: 8), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .alreadyStakedToday)
        }
        XCTAssertEqual(graph.stakes.count, 1)
    }

    func test_forkSeal_dragWritesChosenRoadAndSealsSibling() throws {
        var graph = try planted(days: 3, from: day(2026, 8, 24))
        XCTAssertEqual(graph.veil(of: "knoll", at: day(2026, 8, 26), calendar: calendar), .revealed)
        XCTAssertEqual(graph.veil(of: "ford", at: day(2026, 8, 26), calendar: calendar), .revealed)

        let fogged = graph.dragWalker(to: "stack", at: day(2026, 8, 26), calendar: calendar)
        XCTAssertEqual(fogged, graph)

        graph = graph.dragWalker(to: "knoll", at: day(2026, 8, 26), calendar: calendar)
        XCTAssertEqual(graph.walker.occupiedCampID, "knoll")
        XCTAssertEqual(graph.seals.count, 1)
        XCTAssertEqual(graph.seals.first?.chosenCampID, "knoll")
        XCTAssertEqual(graph.seals.first?.sealedCampID, "ford")
        XCTAssertEqual(graph.committedRoads.count, 1)
        XCTAssertEqual(graph.sealedRoads.count, 1)
        XCTAssertEqual(graph.veil(of: "ford", at: day(2026, 8, 26), calendar: calendar), .sealed)
        XCTAssertEqual(graph.veil(of: "knoll", at: day(2026, 8, 26), calendar: calendar), .occupied)

        let towardSealed = graph.dragWalker(to: "ford", at: day(2026, 8, 26), calendar: calendar)
        XCTAssertEqual(towardSealed.walker.occupiedCampID, "knoll")
        XCTAssertEqual(towardSealed.seals.count, 1)
        XCTAssertNil(graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))
    }

    func test_furtherStakeDoesNotPickRoad() throws {
        var graph = try planted(days: 3, from: day(2026, 8, 24))
        graph = try graph.stake(at: day(2026, 8, 27), calendar: calendar)
        XCTAssertEqual(graph.walker.occupiedCampID, WaymapAtlas.gateID)
        XCTAssertTrue(graph.roads.isEmpty)
        XCTAssertNotNil(graph.revealedFork(at: day(2026, 8, 27), calendar: calendar))
    }

    func test_missedDayClosesForkUntilStreakRebuilds() throws {
        var graph = try planted(days: 3, from: day(2026, 8, 24))
        XCTAssertNotNil(graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))
        XCTAssertNil(graph.revealedFork(at: day(2026, 8, 28), calendar: calendar))
        graph = try graph.stake(at: day(2026, 8, 28), calendar: calendar)
        XCTAssertEqual(graph.campStreak(at: day(2026, 8, 28), calendar: calendar), 1)
        XCTAssertNil(graph.revealedFork(at: day(2026, 8, 28), calendar: calendar))
    }

    func test_architecture_singleGraphWrite_commitDoesNotForkACopy() throws {
        let graph = try planted(days: 3, from: day(2026, 8, 24))
        let committed = graph.dragWalker(to: "ford", at: day(2026, 8, 26), calendar: calendar)
        XCTAssertEqual(graph.walker.occupiedCampID, WaymapAtlas.gateID)
        XCTAssertTrue(graph.seals.isEmpty)
        XCTAssertEqual(committed.seals.count, 1)
        XCTAssertEqual(committed.roads.count, 2)
        XCTAssertEqual(committed.committedRoads.first?.toCampID, "ford")
        XCTAssertEqual(committed.sealedRoads.first?.toCampID, "knoll")
        let labels = Mirror(reflecting: WaymapLedger.sealed(from: committed)).children.compactMap(\.label)
        XCTAssertFalse(labels.contains("level"))
        XCTAssertFalse(labels.contains("revealedFork"))
        XCTAssertEqual(committed.party.level, 1 + committed.totalXP / 100)
    }

    func test_dayKeyIsYYYYMMDD_fromStartOfDay() {
        XCTAssertEqual(CairnDay.key(for: day(2026, 8, 29, hour: 8), calendar: calendar), 20260829)
        XCTAssertEqual(CairnDay.key(for: day(2026, 8, 29, hour: 21), calendar: calendar), 20260829)
        XCTAssertEqual(CairnDay.previous(of: 20260829, calendar: calendar), 20260828)
    }

    private func planted(days: Int, from start: Date) throws -> WaymapGraph {
        var graph = WaymapGraph.empty
        for offset in 0 ..< days {
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            graph = try graph.stake(at: date, calendar: calendar)
        }
        return graph
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
