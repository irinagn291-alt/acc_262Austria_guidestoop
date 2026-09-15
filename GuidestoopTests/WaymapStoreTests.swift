import XCTest
@testable import Guidestoop

final class WaymapStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "gds.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesStakeAndSeal() async throws {
        let store = makeStore()
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 24), calendar: calendar)
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 25), calendar: calendar)
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 26), calendar: calendar)
        _ = try await store.dragWalker(to: "knoll", at: day(2026, 8, 26), calendar: calendar)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.graph.stakes.count, 3)
        XCTAssertEqual(loaded.graph.walker.occupiedCampID, "knoll")
        XCTAssertEqual(loaded.graph.seals.first?.sealedCampID, "ford")
        XCTAssertEqual(loaded.graph.totalXP, 30)
        XCTAssertEqual(loaded.graph.stakes.first?.dayKey, 20260824)
    }

    func test_foggedDragStaysInMemoryUnwritten() async throws {
        let store = makeStore()
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 24), calendar: calendar)
        let afterStake = defaults.data(forKey: WaymapKey.snapshot)
        _ = try await store.dragWalker(to: "knoll", at: day(2026, 8, 24), calendar: calendar)
        XCTAssertEqual(defaults.data(forKey: WaymapKey.snapshot), afterStake)
        let memory = await store.graph()
        XCTAssertEqual(memory.walker.occupiedCampID, WaymapAtlas.gateID)
        XCTAssertTrue(memory.seals.isEmpty)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = try await store.stake(named: nil, value: 12, at: day(2026, 8, 24), calendar: calendar)
        if let good = defaults.data(forKey: WaymapKey.snapshot) {
            defaults.set(good, forKey: WaymapKey.backup)
        }
        let file = directory.appendingPathComponent("waymap.json")
        let backup = directory.appendingPathComponent("waymap.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: WaymapKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.graph.stakes.count, 1)
        XCTAssertEqual(loaded.graph.totalXP, 12)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: WaymapKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("waymap.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.graph.stakes.isEmpty)
        XCTAssertEqual(loaded.graph.totalXP, 0)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let ledger = WaymapLedger.sealed(from: WaymapSeed.graph(now: day(2026, 8, 29), calendar: calendar))
        let data = try WaymapCodec.encode(ledger)
        let decoded = try WaymapCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.stakes.count, 6)
        XCTAssertEqual(decoded.occupiedCampID, "knoll")
        XCTAssertNil(Mirror(reflecting: decoded).children.first { $0.label == "level" })

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try WaymapCodec.decode(future)) { error in
            XCTAssertEqual(error as? WaymapCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try WaymapCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? WaymapCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 24), calendar: calendar)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.graph.stakes.isEmpty)
        XCTAssertNil(defaults.data(forKey: WaymapKey.snapshot))
        XCTAssertNil(defaults.data(forKey: WaymapKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_seedGraphOccupiesCampWithThreeDayGate() {
        let seeded = WaymapSeed.graph(now: day(2026, 8, 29), calendar: calendar)
        XCTAssertTrue(seeded.onboardingComplete)
        XCTAssertEqual(seeded.walker.occupiedCampID, "knoll")
        XCTAssertEqual(seeded.stakes.count, 6)
        XCTAssertEqual(seeded.totalXP, 66)
        XCTAssertEqual(seeded.partyStreak(at: day(2026, 8, 29), calendar: calendar), 6)
        XCTAssertEqual(seeded.campStreak(at: day(2026, 8, 29), calendar: calendar), 3)
        XCTAssertEqual(seeded.committedRoads.count, 1)
        XCTAssertEqual(seeded.sealedRoads.count, 1)
        XCTAssertNotNil(seeded.revealedFork(at: day(2026, 8, 29), calendar: calendar))
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded(now: day(2026, 8, 29), calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: day(2026, 8, 29), calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.stakes.count, 6)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.stakes.first?.id, WaymapSeed.stakeA)
        XCTAssertTrue(first?.showsSeededWaymap(at: day(2026, 8, 29), calendar: calendar) == true)
        XCTAssertTrue(defaults.bool(forKey: WaymapKey.demo))
        XCTAssertNotNil(defaults.data(forKey: WaymapKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("waymap.json").path))
    }

    func test_staleDemoWithoutOpenRoadsReseeds() async throws {
        let store = makeStore()
        _ = try await store.stake(named: nil, value: nil, at: day(2026, 8, 20), calendar: calendar)
        defaults.set(true, forKey: WaymapKey.demo)
        let seeded = try await store.seedDemoIfNeeded(now: day(2026, 8, 29), calendar: calendar)
        XCTAssertNotNil(seeded)
        XCTAssertEqual(seeded?.walker.occupiedCampID, "knoll")
        XCTAssertNotNil(seeded?.revealedFork(at: day(2026, 8, 29), calendar: calendar))
        XCTAssertTrue(seeded?.showsSeededWaymap(at: day(2026, 8, 29), calendar: calendar) == true)
    }
    #endif

    private func makeStore() -> WaymapStore {
        WaymapStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
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
