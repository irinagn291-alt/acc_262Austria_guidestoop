import SwiftUI
@testable import Guidestoop

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("map", AnyView(WaymapView())),
            ("journal", AnyView(JournalView())),
            ("hero", AnyView(HeroView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
