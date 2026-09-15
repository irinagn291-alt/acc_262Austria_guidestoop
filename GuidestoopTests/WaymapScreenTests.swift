import SwiftUI
import XCTest
@testable import Guidestoop

@MainActor
final class WaymapScreenTests: XCTestCase {
    func test_screensConstructWithNoArguments() {
        _ = MapView()
        _ = WaymapView()
        _ = JournalView()
        _ = HeroView()
        _ = SettingsView()
        _ = OnboardingView()
        _ = ForkSealView()
        XCTAssertEqual(String(describing: MapView.self), "MapView")
        XCTAssertEqual(String(describing: WaymapView.self), "WaymapView")
        XCTAssertEqual(String(describing: JournalView.self), "JournalView")
        XCTAssertEqual(String(describing: HeroView.self), "HeroView")
        XCTAssertEqual(String(describing: SettingsView.self), "SettingsView")
    }

    func test_snapshot_mainScreensRender() {
        let catalog: [(String, AnyView)] = [
            ("map", AnyView(MapView())),
            ("journal", AnyView(JournalView())),
            ("hero", AnyView(HeroView())),
            ("settings", AnyView(SettingsView())),
            ("onboarding", AnyView(OnboardingView())),
            ("fork", AnyView(ForkSealView())),
        ]
        for (name, view) in catalog {
            let renderer = ImageRenderer(content: view.frame(width: 390, height: 844))
            renderer.scale = 1
            XCTAssertNotNil(renderer.uiImage, name)
        }
    }

    func test_emptyPopulatedErrorFixtures() {
        XCTAssertTrue(WaymapFixture.vacant().graph.stakes.isEmpty)
        XCTAssertFalse(WaymapFixture.populated().graph.stakes.isEmpty)
        XCTAssertEqual(WaymapFixture.committed().graph.committedRoads.count, 1)
        XCTAssertEqual(WaymapFixture.committed().graph.sealedRoads.count, 1)
        XCTAssertEqual(WaymapFixture.committed().graph.walker.occupiedCampID, "knoll")
        XCTAssertTrue(WaymapFixture.populated().canStake(at: Date()))
        XCTAssertEqual(WaymapFixture.faulted().warning, .startedEmpty)
    }

    func test_layout_centeringPanPutsCampAtMid() {
        let layout = WaymapLayout(size: CGSize(width: 400, height: 400), pan: .zero, scale: 1)
        let camp = Camp(id: "mid", title: "Mid", value: 1, east: 0.5, north: 0.5)
        let pan = layout.centeringPan(for: camp)
        let focused = WaymapLayout(size: layout.size, pan: pan, scale: 1)
        let point = focused.point(for: camp)
        XCTAssertEqual(point.x, 200, accuracy: 0.5)
        XCTAssertEqual(point.y, 200, accuracy: 0.5)
    }

    func test_seededSceneOccupiesCampAndOpensTwoRoads() {
        let watch = WaymapFixture.populated()
        let now = Date()
        XCTAssertEqual(watch.graph.walker.occupiedCampID, "knoll")
        XCTAssertTrue(watch.canStake(at: now))
        let fork = watch.graph.revealedFork(at: now, calendar: .current)
        XCTAssertNotNil(fork)
        let scene = WaymapScene.focused(graph: watch.graph, now: now, calendar: .current)
        XCTAssertNotNil(scene.unit(for: "knoll"))
        XCTAssertNotNil(scene.unit(for: fork?.left.id ?? ""))
        XCTAssertNotNil(scene.unit(for: fork?.right.id ?? ""))
        XCTAssertEqual(scene.campIDs.count, 3)
        XCTAssertFalse(scene.campIDs.contains("hollow"))
        XCTAssertFalse(scene.campIDs.contains("gall"))
        XCTAssertFalse(scene.campIDs.contains("stoop"))
        XCTAssertFalse(scene.campIDs.contains("ford"))
        let trail = WaymapScene.trail(graph: watch.graph, now: now, calendar: .current)
        XCTAssertEqual(trail.campIDs.count, 3)
        XCTAssertTrue(trail.campIDs.contains("knoll"))
        XCTAssertTrue(trail.campIDs.contains(fork?.left.id ?? ""))
        XCTAssertTrue(trail.campIDs.contains(fork?.right.id ?? ""))
        XCTAssertFalse(trail.campIDs.contains("stoop"))
        XCTAssertFalse(trail.campIDs.contains("ford"))
        XCTAssertTrue(watch.graph.showsSeededWaymap(at: now, calendar: .current))
    }

    func test_designTokensNameSFProAndPaletteHex() {
        XCTAssertEqual(MoorVellum.face, "SF Pro")
        XCTAssertEqual(MoorVellum.Step.allCases.count, 6)
        XCTAssertEqual(MoorVellum.Hex.background, "#EDE6D4")
        XCTAssertEqual(MoorVellum.Hex.surface, "#D8CFBC")
        XCTAssertEqual(MoorVellum.Hex.ink, "#1E1914")
        XCTAssertEqual(MoorVellum.Hex.accent, "#33501F")
        XCTAssertEqual(MoorVellum.Hex.muted, "#565046")
        XCTAssertEqual(MoorVellum.tap, 44)
        XCTAssertEqual(WaymapFigures.count(1200, locale: Locale(identifier: "en_US")), "1,200")
    }
}
