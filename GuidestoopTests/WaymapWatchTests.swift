import XCTest
@testable import Guidestoop

@MainActor
final class WaymapWatchTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }()

    func test_architecture_watchHoldsOneGraph_dragDoesNotLeaveAForkedCopy() async throws {
        let planted = try planted(days: 3, from: day(2026, 8, 24))
        let watch = WaymapWatch(
            store: WaymapMemory(graph: planted),
            graph: planted,
            shouldLoad: false,
            calendar: calendar
        )
        XCTAssertEqual(watch.graph.walker.occupiedCampID, WaymapAtlas.gateID)
        XCTAssertTrue(watch.graph.seals.isEmpty)

        await watch.dragWalker(to: "knoll", at: day(2026, 8, 26))
        XCTAssertEqual(watch.graph.walker.occupiedCampID, "knoll")
        XCTAssertEqual(watch.graph.seals.count, 1)
        XCTAssertEqual(watch.graph.committedRoads.count, 1)
        XCTAssertEqual(watch.graph.sealedRoads.first?.toCampID, "ford")
        XCTAssertNil(watch.graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))

        let again = watch.graph
        await watch.dragWalker(to: "ford", at: day(2026, 8, 26))
        XCTAssertEqual(watch.graph, again)
    }

    func test_familyInvariant_throughWatch_stakeStreakForkXPLevelBoss() async throws {
        let watch = WaymapWatch(
            store: WaymapMemory(),
            graph: WaymapGraph.empty.settingOnboardingComplete(true),
            shouldLoad: false,
            calendar: calendar
        )
        await watch.stake(at: day(2026, 8, 24))
        XCTAssertEqual(watch.graph.stakes.count, 1)
        await watch.stake(at: day(2026, 8, 24, hour: 21))
        XCTAssertEqual(watch.fault, .alreadyStakedToday)
        XCTAssertEqual(watch.graph.stakes.count, 1)

        await watch.stake(at: day(2026, 8, 25))
        await watch.stake(at: day(2026, 8, 26))
        XCTAssertEqual(watch.graph.partyStreak(at: day(2026, 8, 26), calendar: calendar), 3)
        XCTAssertEqual(watch.graph.totalXP, 30)
        XCTAssertEqual(watch.graph.party.level, 1 + watch.graph.totalXP / 100)
        XCTAssertNotNil(watch.graph.revealedFork(at: day(2026, 8, 26), calendar: calendar))

        await watch.stake(at: day(2026, 8, 27))
        await watch.stake(at: day(2026, 8, 28))
        XCTAssertEqual(watch.graph.weekStakeCount(at: day(2026, 8, 28), calendar: calendar), 5)
        XCTAssertTrue(watch.graph.ridge(at: day(2026, 8, 28), calendar: calendar).isOpen)
        let before = watch.graph.totalXP
        await watch.claimRidge(at: day(2026, 8, 28))
        XCTAssertEqual(watch.graph.totalXP, before + RidgeBoss.bonusXP)
        XCTAssertEqual(watch.graph.party.level, 1 + watch.graph.totalXP / 100)
    }

    func test_showCampFocusesCampAndClosesSheet() {
        let watch = WaymapFixture.committed()
        watch.sheet = .journal
        watch.showCamp("rise")
        XCTAssertEqual(watch.focusedCampID, "rise")
        XCTAssertEqual(watch.focusNonce, 1)
        XCTAssertNil(watch.sheet)
    }

    func test_reviewScreen_logAndGoals_todayStaysOnMap() {
        XCTAssertEqual(WaymapReview.sheet(from: ["-ReviewScreen", "log"]), .journal)
        XCTAssertEqual(WaymapReview.sheet(from: ["-ReviewScreen", "goals"]), .hero)
        XCTAssertNil(WaymapReview.sheet(from: ["-ReviewScreen", "today"]))
        XCTAssertNil(WaymapReview.sheet(from: []))
    }

    func test_finishOnboardingWritesCompletionFlag() async {
        let watch = WaymapWatch(store: WaymapMemory(), shouldLoad: false, calendar: calendar)
        XCTAssertFalse(watch.graph.onboardingComplete)
        await watch.finishOnboarding()
        XCTAssertTrue(watch.graph.onboardingComplete)
        XCTAssertFalse(watch.showOnboarding)
    }

    func test_resetClearsGraphAndReopensCover() async {
        var graph = WaymapGraph.empty.settingOnboardingComplete(true)
        graph = (try? graph.stake(at: day(2026, 8, 24), calendar: calendar)) ?? graph
        let watch = WaymapWatch(
            store: WaymapMemory(graph: graph),
            graph: graph,
            shouldLoad: false,
            calendar: calendar
        )
        await watch.resetAllData()
        XCTAssertTrue(watch.graph.stakes.isEmpty)
        XCTAssertTrue(watch.showOnboarding)
        XCTAssertEqual(watch.graph.totalXP, 0)
    }

    private func planted(days: Int, from start: Date) throws -> WaymapGraph {
        var graph = WaymapGraph.empty.settingOnboardingComplete(true)
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
