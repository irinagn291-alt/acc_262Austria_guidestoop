import QuartzCore
import SwiftUI
import UIKit
import XCTest
@testable import Guidestoop

@MainActor
final class ScreenShotTests: XCTestCase {
    func test_coversRequiredScreens() {
        let names = Set(ScreenCatalog.shots.map(\.0))
        for key in ["map", "journal", "hero", "settings"] {
            XCTAssertTrue(names.contains(key), "missing \(key) snapshot")
        }
        XCTAssertGreaterThanOrEqual(ScreenCatalog.shots.count, 3)
    }

    func test_renderKeyScreens() throws {
        let dir = try shotDir()
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        let prefix = pad ? "ipad" : "iphone"
        let size = pad ? CGSize(width: 1024, height: 1366) : CGSize(width: 390, height: 844)
        for (name, view) in ScreenCatalog.shots {
            let data = render(view, size: size)
            XCTAssertGreaterThan(data.count, 8000, name)
            try data.write(to: dir.appendingPathComponent("\(prefix)-\(name).png"))
        }
    }

    private func shotDir() throws -> URL {
        if let env = ProcessInfo.processInfo.environment["GF_SHOT_DIR"], !env.isEmpty {
            try FileManager.default.createDirectory(
                atPath: env, withIntermediateDirectories: true
            )
            return URL(fileURLWithPath: env)
        }
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(".gf-shots")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func render<V: View>(_ view: V, size: CGSize) -> Data {
        let host = UIHostingController(
            rootView: view
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
        )
        host.safeAreaRegions = []
        host.view.bounds = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .black
        host.view.insetsLayoutMarginsFromSafeArea = false
        let frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            host.view.layer.render(in: ctx.cgContext)
        }
        window.isHidden = true
        window.rootViewController = nil
        return image.pngData() ?? Data()
    }
}
