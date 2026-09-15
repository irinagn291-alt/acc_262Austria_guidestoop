import XCTest
@testable import Guidestoop

/// Family habit_rpg: one stake/day, streak iff yesterday, reveal at 3, XP += value, level = 1 + totalXP/100, boss at 5.
final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        calendar = posixCalendar()
    }

    func test_oneStakePerDay_secondPlantRefused() throws {
        var graph = WaymapGraph.empty
        graph = try graph.stake(at: day(2026, 8, 24), calendar: calendar)
        XCTAssertEqual(graph.stakes.count, 1)
        XCTAssertThrowsError(try graph.stake(at: day(2026, 8, 24, hour: 21), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .alreadyStakedToday)
        }
        XCTAssertEqual(graph.stakes.count, 1)
        XCTAssertEqual(graph.totalXP, 10)
    }

    func test_streakContinuesIffYesterday() throws {
        var graph = WaymapGraph.empty
        graph = try graph.stake(at: day(2026, 8, 24), calendar: calendar)
        graph = try graph.stake(at: day(2026, 8, 25), calendar: calendar)
        XCTAssertEqual(graph.partyStreak(at: day(2026, 8, 25), calendar: calendar), 2)
        XCTAssertEqual(graph.partyStreak(at: day(2026, 8, 26), calendar: calendar), 2)

        XCTAssertEqual(graph.partyStreak(at: day(2026, 8, 27), calendar: calendar), 0)
        graph = try graph.stake(at: day(2026, 8, 27), calendar: calendar)
        XCTAssertEqual(graph.partyStreak(at: day(2026, 8, 27), calendar: calendar), 1)
    }

    func test_unlockNextNodeAtStreakThree_xpAddsValue_levelFromTotalXP() throws {
        var graph = WaymapGraph.empty
        XCTAssertNil(graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))
        XCTAssertTrue(graph.isPathClosed(at: day(2026, 8, 24), calendar: calendar))

        graph = try graph.stake(value: 20, at: day(2026, 8, 24), calendar: calendar)
        graph = try graph.stake(value: 30, at: day(2026, 8, 25), calendar: calendar)
        XCTAssertNil(graph.revealedFork(at: day(2026, 8, 25), calendar: calendar))
        XCTAssertEqual(graph.totalXP, 50)
        XCTAssertEqual(graph.party.level, 1 + graph.totalXP / 100)

        graph = try graph.stake(value: 50, at: day(2026, 8, 26), calendar: calendar)
        XCTAssertEqual(graph.totalXP, 100)
        XCTAssertEqual(graph.party.level, 1 + graph.totalXP / 100)
        XCTAssertEqual(graph.party.level, 2)
        let fork = try XCTUnwrap(graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))
        XCTAssertEqual(fork.left.id, "knoll")
        XCTAssertEqual(fork.right.id, "ford")
    }

    func test_bossOpensAfterFiveCompletions_bonusAddsToTotalXP() throws {
        var graph = WaymapGraph.empty
        for offset in 0 ..< 4 {
            graph = try graph.stake(at: day(2026, 8, 24 + offset), calendar: calendar)
        }
        XCTAssertFalse(graph.ridge(at: day(2026, 8, 27), calendar: calendar).isOpen)
        XCTAssertThrowsError(try graph.claimRidge(at: day(2026, 8, 27), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .ridgeShut)
        }

        graph = try graph.stake(at: day(2026, 8, 28), calendar: calendar)
        XCTAssertEqual(graph.weekStakeCount(at: day(2026, 8, 28), calendar: calendar), 5)
        XCTAssertTrue(graph.ridge(at: day(2026, 8, 28), calendar: calendar).isOpen)
        let before = graph.totalXP
        graph = try graph.claimRidge(at: day(2026, 8, 28), calendar: calendar)
        XCTAssertEqual(graph.totalXP, before + RidgeBoss.bonusXP)
        XCTAssertEqual(graph.party.level, 1 + graph.totalXP / 100)
        XCTAssertThrowsError(try graph.claimRidge(at: day(2026, 8, 28), calendar: calendar)) { error in
            XCTAssertEqual(error as? WaymapFault, .ridgeSpent)
        }
    }

    private func posixCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
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
