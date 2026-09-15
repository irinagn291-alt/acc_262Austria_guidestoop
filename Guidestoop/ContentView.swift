import SwiftUI

@MainActor
struct ContentView: View {
    @State private var watch = WaymapWatch.live()

    var body: some View {
        MapView(watch: watch, handlesLaunch: true)
    }
}

#Preview {
    MapView()
}
