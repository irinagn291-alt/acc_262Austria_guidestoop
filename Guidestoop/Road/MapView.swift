import SwiftUI

/// Role: Road. Spec 3.6 Map screen. Thin wrap over the waymap root.
@MainActor
struct MapView: View {
    @Bindable var watch: WaymapWatch
    var handlesLaunch: Bool

    init(watch: WaymapWatch, handlesLaunch: Bool = true) {
        self.watch = watch
        self.handlesLaunch = handlesLaunch
    }

    init() {
        self.init(watch: WaymapFixture.populated(), handlesLaunch: false)
    }

    var body: some View {
        WaymapView(watch: watch, handlesLaunch: handlesLaunch)
    }
}
