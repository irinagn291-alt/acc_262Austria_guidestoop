import Foundation

/// Role: Seal. UserDefaults / file envelope. Reveal and level never travel with this document.
struct WaymapLedger: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var occupiedCampID: String
    var stakes: [StakeRecord]
    var roads: [RoadRecord]
    var seals: [ForkSeal]
    var totalXP: Int
    var claimedRidgeWeeks: [Int]
    var choreName: String
    var choreValue: Int
    var onboardingComplete: Bool

    static func sealed(from graph: WaymapGraph) -> WaymapLedger {
        WaymapLedger(
            schemaVersion: WaymapCodec.currentSchema,
            occupiedCampID: graph.walker.occupiedCampID,
            stakes: graph.stakes.map { stake in
                StakeRecord(
                    id: stake.id,
                    campID: stake.campID,
                    choreName: stake.choreName,
                    dayKey: stake.dayKey,
                    value: stake.value,
                    plantedEpoch: stake.plantedAt.timeIntervalSince1970
                )
            },
            roads: graph.roads.map { road in
                RoadRecord(
                    id: road.id,
                    fromCampID: road.fromCampID,
                    toCampID: road.toCampID,
                    isSealed: road.isSealed
                )
            },
            seals: graph.seals,
            totalXP: graph.totalXP,
            claimedRidgeWeeks: graph.claimedRidgeWeeks,
            choreName: graph.chore.name,
            choreValue: graph.chore.value,
            onboardingComplete: graph.onboardingComplete
        )
    }

    func asGraph() -> WaymapGraph {
        WaymapGraph(
            walker: Walker(occupiedCampID: occupiedCampID),
            stakes: stakes.map { record in
                CampStake(
                    id: record.id,
                    campID: record.campID,
                    choreName: record.choreName,
                    dayKey: record.dayKey,
                    value: record.value,
                    plantedAt: Date(timeIntervalSince1970: record.plantedEpoch)
                )
            },
            roads: roads.map { record in
                Road(
                    id: record.id,
                    fromCampID: record.fromCampID,
                    toCampID: record.toCampID,
                    isSealed: record.isSealed
                )
            },
            seals: seals,
            totalXP: totalXP,
            claimedRidgeWeeks: claimedRidgeWeeks,
            chore: CampChore(name: choreName, value: choreValue),
            onboardingComplete: onboardingComplete
        )
    }
}

struct StakeRecord: Codable, Equatable, Sendable {
    var id: UUID
    var campID: String
    var choreName: String
    var dayKey: Int
    var value: Int
    var plantedEpoch: TimeInterval
}

struct RoadRecord: Codable, Equatable, Sendable {
    var id: UUID
    var fromCampID: String
    var toCampID: String
    var isSealed: Bool
}

/// Role: Seal. Schema switch. Domain types never decode this JSON themselves.
enum WaymapCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: WaymapLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(ledger)
    }

    static func decode(_ data: Data) throws -> WaymapLedger {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(WaymapLedger.self, from: data)
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
