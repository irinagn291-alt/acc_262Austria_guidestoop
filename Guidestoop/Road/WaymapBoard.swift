import SwiftUI

/// Role: Road. Occupied camp plus the two forward roads fill the canvas. Atlas coords are fallback.
struct WaymapScene: Equatable {
    var slots: [String: CGPoint]

    static func focused(graph: WaymapGraph, now: Date, calendar: Calendar) -> WaymapScene {
        var slots: [String: CGPoint] = [:]
        let occupied = graph.walker.occupiedCampID
        if let fork = graph.revealedFork(at: now, calendar: calendar) {
            slots[occupied] = CGPoint(x: 0.50, y: 0.72)
            slots[fork.left.id] = CGPoint(x: 0.16, y: 0.20)
            slots[fork.right.id] = CGPoint(x: 0.84, y: 0.20)
            return WaymapScene(slots: slots)
        }
        slots[occupied] = CGPoint(x: 0.50, y: 0.62)
        if let pair = WaymapAtlas.pair(from: occupied),
           !graph.seals.contains(where: { $0.originCampID == occupied }) {
            slots[pair.0.id] = CGPoint(x: 0.18, y: 0.22)
            slots[pair.1.id] = CGPoint(x: 0.82, y: 0.22)
        } else if let seal = graph.seals.last {
            if slots[seal.originCampID] == nil {
                slots[seal.originCampID] = CGPoint(x: 0.50, y: 0.86)
            }
            if slots[seal.chosenCampID] == nil {
                slots[seal.chosenCampID] = CGPoint(x: 0.28, y: 0.86)
            }
            if slots[seal.sealedCampID] == nil {
                slots[seal.sealedCampID] = CGPoint(x: 0.86, y: 0.58)
            }
        }
        return WaymapScene(slots: slots)
    }

    /// Occupied camp plus the two forward roads. Inset trails stay a clean fork.
    static func trail(graph: WaymapGraph, now: Date, calendar: Calendar) -> WaymapScene {
        var slots: [String: CGPoint] = [:]
        let occupied = graph.walker.occupiedCampID
        slots[occupied] = CGPoint(x: 0.50, y: 0.74)
        if let fork = graph.revealedFork(at: now, calendar: calendar) {
            slots[fork.left.id] = CGPoint(x: 0.16, y: 0.22)
            slots[fork.right.id] = CGPoint(x: 0.84, y: 0.22)
        } else if let pair = WaymapAtlas.pair(from: occupied),
                  !graph.seals.contains(where: { $0.originCampID == occupied }) {
            slots[pair.0.id] = CGPoint(x: 0.16, y: 0.22)
            slots[pair.1.id] = CGPoint(x: 0.84, y: 0.22)
        }
        return WaymapScene(slots: slots)
    }

    func unit(for id: String) -> CGPoint? {
        slots[id]
    }

    var campIDs: Set<String> {
        Set(slots.keys)
    }
}

/// Role: Road. Camp positions on the canvas. Magnify pans/scales; drag is the walker only.
struct WaymapLayout: Equatable {
    var size: CGSize
    var pan: CGSize
    var scale: CGFloat
    var scene: WaymapScene? = nil

    func point(for camp: Camp) -> CGPoint {
        let raw = rawPoint(for: camp)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGPoint(
            x: center.x + (raw.x - center.x) * scale + pan.width,
            y: center.y + (raw.y - center.y) * scale + pan.height
        )
    }

    func centeringPan(for camp: Camp) -> CGSize {
        let raw = rawPoint(for: camp)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGSize(
            width: -(raw.x - center.x) * scale,
            height: -(raw.y - center.y) * scale
        )
    }

    func camp(at drop: CGPoint, radius: CGFloat = 64) -> Camp? {
        let allowed = scene?.campIDs
        var best: Camp?
        var bestDistance = radius
        for camp in WaymapAtlas.camps {
            if let allowed, !allowed.contains(camp.id) { continue }
            let here = point(for: camp)
            let distance = hypot(here.x - drop.x, here.y - drop.y)
            if distance <= bestDistance {
                bestDistance = distance
                best = camp
            }
        }
        return best
    }

    func rawPoint(for camp: Camp) -> CGPoint {
        let inset = MoorVellum.space(3)
        let field = CGRect(
            x: inset,
            y: inset,
            width: max(size.width - inset * 2, 1),
            height: max(size.height - inset * 2, 1)
        )
        let unit = scene?.unit(for: camp.id) ?? CGPoint(x: camp.east, y: 1 - camp.north)
        return CGPoint(
            x: field.minX + unit.x * field.width,
            y: field.minY + unit.y * field.height
        )
    }
}

/// Role: Road. SwiftUI Canvas waymap. Iron-gall roads and cairn piles are Path. Camp names live on Buttons.
struct CairnBoard: View {
    var graph: WaymapGraph
    var now: Date
    var calendar: Calendar
    var pan: CGSize
    var scale: CGFloat
    var walkerDrag: CGSize
    var drawsMarks: Bool = true
    var compact: Bool = false

    var body: some View {
        Canvas { context, size in
            let unit = max(1.2, min(size.width, size.height) / 240)
            let scene = compact
                ? WaymapScene.trail(graph: graph, now: now, calendar: calendar)
                : WaymapScene.focused(graph: graph, now: now, calendar: calendar)
            let layout = WaymapLayout(size: size, pan: pan, scale: scale, scene: scene)
            drawGround(context, size: size)
            for edge in visibleRoads(in: scene) {
                drawRoad(context, edge: edge, layout: layout, unit: unit)
            }
            if drawsMarks {
                for camp in sceneCamps(scene) {
                    let veil = graph.veil(of: camp.id, at: now, calendar: calendar)
                    drawCairn(context, camp: camp, veil: veil, layout: layout, unit: unit)
                }
                if let occupied = WaymapAtlas.camp(id: graph.walker.occupiedCampID) {
                    drawWalker(context, at: layout.point(for: occupied), drag: walkerDrag, unit: unit)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        let scene = WaymapScene.focused(graph: graph, now: now, calendar: calendar)
        let parts = sceneCamps(scene).map { camp in
            let veil = graph.veil(of: camp.id, at: now, calendar: calendar)
            return "\(camp.title), \(MoorVellum.veilCopy(veil))"
        }
        return parts.joined(separator: ". ")
    }

    private func sceneCamps(_ scene: WaymapScene) -> [Camp] {
        WaymapAtlas.camps.filter { scene.campIDs.contains($0.id) }
    }

    private func visibleRoads(in scene: WaymapScene) -> [DisplayRoad] {
        var edges: [DisplayRoad] = graph.roads.compactMap { road in
            guard scene.campIDs.contains(road.fromCampID), scene.campIDs.contains(road.toCampID) else {
                return nil
            }
            return DisplayRoad(
                from: road.fromCampID,
                to: road.toCampID,
                kind: road.isSealed ? .sealed : .chosen
            )
        }
        let occupied = graph.walker.occupiedCampID
        if let fork = graph.revealedFork(at: now, calendar: calendar) {
            if scene.campIDs.contains(fork.left.id) {
                edges.append(DisplayRoad(from: fork.originCampID, to: fork.left.id, kind: .open))
            }
            if scene.campIDs.contains(fork.right.id) {
                edges.append(DisplayRoad(from: fork.originCampID, to: fork.right.id, kind: .open))
            }
        } else if let pair = WaymapAtlas.pair(from: occupied),
                  !graph.seals.contains(where: { $0.originCampID == occupied }) {
            if scene.campIDs.contains(pair.0.id) {
                edges.append(DisplayRoad(from: occupied, to: pair.0.id, kind: .gated))
            }
            if scene.campIDs.contains(pair.1.id) {
                edges.append(DisplayRoad(from: occupied, to: pair.1.id, kind: .gated))
            }
        }
        return edges
    }

    private func drawGround(_ context: GraphicsContext, size: CGSize) {
        var peat = Path()
        peat.move(to: CGPoint(x: 0, y: size.height * 0.48))
        peat.addQuadCurve(
            to: CGPoint(x: size.width, y: size.height * 0.52),
            control: CGPoint(x: size.width * 0.5, y: size.height * 0.40)
        )
        peat.addLine(to: CGPoint(x: size.width, y: size.height))
        peat.addLine(to: CGPoint(x: 0, y: size.height))
        peat.closeSubpath()
        context.fill(peat, with: .color(MoorVellum.Palette.surface))

        var shelf = Path()
        shelf.addRect(CGRect(x: 0, y: size.height * 0.08, width: size.width, height: size.height * 0.28))
        context.fill(shelf, with: .color(MoorVellum.Palette.surface.opacity(0.55)))

        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: size.height * 0.16))
        ridge.addQuadCurve(
            to: CGPoint(x: size.width, y: size.height * 0.14),
            control: CGPoint(x: size.width * 0.5, y: size.height * 0.04)
        )
        context.stroke(ridge, with: .color(MoorVellum.Palette.ink.opacity(0.55)), lineWidth: 3)

        var gall = Path()
        gall.move(to: CGPoint(x: 0, y: size.height * 0.84))
        gall.addQuadCurve(
            to: CGPoint(x: size.width, y: size.height * 0.88),
            control: CGPoint(x: size.width * 0.46, y: size.height * 0.76)
        )
        context.stroke(gall, with: .color(MoorVellum.Palette.ink.opacity(0.5)), lineWidth: 3)
    }

    private func drawRoad(_ context: GraphicsContext, edge: DisplayRoad, layout: WaymapLayout, unit: CGFloat) {
        guard let from = WaymapAtlas.camp(id: edge.from),
              let to = WaymapAtlas.camp(id: edge.to)
        else { return }
        let start = layout.point(for: from)
        let end = layout.point(for: to)
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(
            to: end,
            control: CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - 36 * unit)
        )
        switch edge.kind {
        case .chosen:
            context.stroke(
                path,
                with: .color(MoorVellum.Palette.ink),
                style: StrokeStyle(lineWidth: 6 * unit, lineCap: .round)
            )
        case .sealed:
            context.stroke(
                path,
                with: .color(MoorVellum.Palette.muted),
                style: StrokeStyle(lineWidth: 5 * unit, lineCap: .round, dash: [7, 6])
            )
            var hatch = Path()
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - 18 * unit)
            hatch.move(to: CGPoint(x: mid.x - 12 * unit, y: mid.y - 12 * unit))
            hatch.addLine(to: CGPoint(x: mid.x + 12 * unit, y: mid.y + 12 * unit))
            hatch.move(to: CGPoint(x: mid.x + 12 * unit, y: mid.y - 12 * unit))
            hatch.addLine(to: CGPoint(x: mid.x - 12 * unit, y: mid.y + 12 * unit))
            context.stroke(hatch, with: .color(MoorVellum.Palette.ink), lineWidth: 2.6 * unit)
        case .open:
            context.stroke(
                path,
                with: .color(MoorVellum.Palette.accent),
                style: StrokeStyle(lineWidth: 7 * unit, lineCap: .round)
            )
        case .gated:
            context.stroke(
                path,
                with: .color(MoorVellum.Palette.ink),
                style: StrokeStyle(lineWidth: 4 * unit, lineCap: .round, dash: [10, 7])
            )
        }
    }

    private func drawCairn(_ context: GraphicsContext, camp: Camp, veil: CampVeil, layout: WaymapLayout, unit: CGFloat) {
        let center = layout.point(for: camp)
        let radius: CGFloat
        switch veil {
        case .occupied, .revealed: radius = 22 * unit
        case .committed: radius = 16 * unit
        case .sealed, .fogged: radius = 14 * unit
        }
        let pile = cairnPath(at: center, radius: radius)
        switch veil {
        case .fogged:
            context.fill(pile, with: .color(MoorVellum.Palette.surface))
            context.stroke(pile, with: .color(MoorVellum.Palette.ink), lineWidth: 2)
        case .revealed:
            context.fill(pile, with: .color(MoorVellum.Palette.ink))
            context.stroke(pile, with: .color(MoorVellum.Palette.background), lineWidth: 2.6)
        case .occupied:
            context.fill(pile, with: .color(MoorVellum.Palette.accent))
            context.stroke(pile, with: .color(MoorVellum.Palette.ink), lineWidth: 3)
        case .committed:
            context.fill(pile, with: .color(MoorVellum.Palette.ink))
            context.stroke(pile, with: .color(MoorVellum.Palette.accent), lineWidth: 2)
        case .sealed:
            context.fill(pile, with: .color(MoorVellum.Palette.surface))
            context.stroke(pile, with: .color(MoorVellum.Palette.ink), lineWidth: 2.4)
            var cross = Path()
            cross.move(to: CGPoint(x: center.x - 10 * unit, y: center.y - 10 * unit))
            cross.addLine(to: CGPoint(x: center.x + 10 * unit, y: center.y + 10 * unit))
            cross.move(to: CGPoint(x: center.x + 10 * unit, y: center.y - 10 * unit))
            cross.addLine(to: CGPoint(x: center.x - 10 * unit, y: center.y + 10 * unit))
            context.stroke(cross, with: .color(MoorVellum.Palette.ink), lineWidth: 2.2)
        }
    }

    private func drawWalker(_ context: GraphicsContext, at point: CGPoint, drag: CGSize, unit: CGFloat) {
        let here = CGPoint(x: point.x + drag.width, y: point.y + drag.height - 28 * unit)
        let token = CGRect(x: here.x - 16 * unit, y: here.y - 16 * unit, width: 32 * unit, height: 32 * unit)
        context.fill(Path(ellipseIn: token), with: .color(MoorVellum.Palette.background))
        context.stroke(Path(ellipseIn: token), with: .color(MoorVellum.Palette.ink), lineWidth: 2.6)
        var mark = Path()
        mark.addEllipse(in: token.insetBy(dx: 8 * unit, dy: 8 * unit))
        context.fill(mark, with: .color(MoorVellum.Palette.accent))
    }

    private func cairnPath(at point: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius * 0.15, width: radius * 2, height: radius))
        path.addEllipse(in: CGRect(x: point.x - radius * 0.7, y: point.y - radius * 0.95, width: radius * 1.4, height: radius * 0.9))
        path.addEllipse(in: CGRect(x: point.x - radius * 0.35, y: point.y - radius * 1.45, width: radius * 0.7, height: radius * 0.6))
        return path
    }
}

private struct DisplayRoad {
    enum Kind {
        case chosen
        case sealed
        case open
        case gated
    }

    var from: String
    var to: String
    var kind: Kind
}
