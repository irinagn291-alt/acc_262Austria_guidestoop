import Foundation

/// Role: Seal. Preference keys. Snapshot key is the assigned UserDefaults contract.
enum WaymapKey {
    static let snapshot = "gds.waymap.v1"
    static let backup = "gds.waymap.v1.backup"
    static let demo = "gds.demo.v3"
}

/// Role: Seal. Recoverable load outcome. Never crash on a corrupt snapshot.
enum WaymapWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Seal. The only persistence seam. Views observe the graph; they never touch UserDefaults or files.
protocol WaymapStoring: Sendable {
    func load() async -> (graph: WaymapGraph, warning: WaymapWarning?)
    func graph() async -> WaymapGraph
    func stake(named: String?, value: Int?, at: Date, calendar: Calendar) async throws -> WaymapGraph
    func dragWalker(to: String, at: Date, calendar: Calendar) async throws -> WaymapGraph
    func claimRidge(at: Date, calendar: Calendar) async throws -> WaymapGraph
    func setOnboardingComplete(_ done: Bool) async throws -> WaymapGraph
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> WaymapGraph?
}

/// Role: Seal. Memory is the source of truth. gds.waymap.v1 plus an Application Support file are projections.
actor WaymapStore: WaymapStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: WaymapGraph = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: WaymapWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Guidestoop", isDirectory: true)
    }

    func load() async -> (graph: WaymapGraph, warning: WaymapWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: WaymapKey.snapshot), let graph = decode(data) {
            latest = graph
            return (latest, nil)
        }
        if let graph = decodeFile(fileURL) {
            latest = graph
            return (latest, nil)
        }
        if let data = defaults.data(forKey: WaymapKey.backup), let graph = decode(data) {
            latest = graph
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let graph = decodeFile(backupURL) {
            latest = graph
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: WaymapKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func graph() async -> WaymapGraph {
        latest
    }

    func stake(
        named: String? = nil,
        value: Int? = nil,
        at date: Date,
        calendar: Calendar
    ) async throws -> WaymapGraph {
        latest = try latest.stake(named: named, value: value, at: date, calendar: calendar)
        try persistNow()
        return latest
    }

    func dragWalker(to campID: String, at date: Date, calendar: Calendar) async throws -> WaymapGraph {
        let next = latest.dragWalker(to: campID, at: date, calendar: calendar)
        guard next != latest else { return latest }
        latest = next
        try persistNow()
        return latest
    }

    func claimRidge(at date: Date, calendar: Calendar) async throws -> WaymapGraph {
        latest = try latest.claimRidge(at: date, calendar: calendar)
        try persistNow()
        return latest
    }

    func setOnboardingComplete(_ done: Bool) async throws -> WaymapGraph {
        latest = latest.settingOnboardingComplete(done)
        try persistNow()
        return latest
    }

    func note(_ graph: WaymapGraph) async {
        latest = graph
        dirty = true
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistNow()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: WaymapKey.snapshot)
        defaults.removeObject(forKey: WaymapKey.backup)
        defaults.removeObject(forKey: WaymapKey.demo)
        defaults.synchronize()
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> WaymapGraph? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        let already = defaults.object(forKey: WaymapKey.demo) != nil
        if already && latest.showsSeededWaymap(at: now, calendar: calendar) {
            return nil
        }
        latest = WaymapSeed.graph(now: now, calendar: calendar)
        try persistNow()
        defaults.set(true, forKey: WaymapKey.demo)
        defaults.synchronize()
        return latest
        #else
        return nil
        #endif
    }

    private func persistNow() throws {
        let ledger = WaymapLedger.sealed(from: latest)
        let data = try WaymapCodec.encode(ledger)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: WaymapKey.snapshot) {
            defaults.set(previous, forKey: WaymapKey.backup)
        }
        defaults.set(data, forKey: WaymapKey.snapshot)
        defaults.synchronize()
        prepareDirectory()
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistNow()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> WaymapGraph? {
        guard let ledger = try? WaymapCodec.decode(data) else { return nil }
        return ledger.asGraph()
    }

    private func decodeFile(_ url: URL) -> WaymapGraph? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("waymap.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("waymap.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
