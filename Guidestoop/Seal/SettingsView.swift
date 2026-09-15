import SwiftUI

/// Role: Seal. Settings sheet. Contact, re-run onboarding, confirmed reset.
@MainActor
struct SettingsView: View {
    var watch: WaymapWatch
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var confirmReset = false
    @State private var resetBusy = false

    init(watch: WaymapWatch) {
        self.watch = watch
    }

    init() {
        self.init(watch: WaymapFixture.populated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
            VellumSheetBar(title: "Settings", closeLabel: "Close settings") {
                dismiss()
            }
            if watch.persistFailed {
                errorState
            } else if watch.graph.stakes.isEmpty {
                VellumVacancy(
                    image: "gds_EmptyList",
                    headline: "The waymap is blank.",
                    line: "Stake a cairn, or open the contact leaf.",
                    actionTitle: "Back to the waymap"
                ) {
                    dismiss()
                }
                actions
            } else {
                populated
            }
        }
        .padding(MoorVellum.space(2))
        .vellumColumn()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MoorVellum.Palette.background.ignoresSafeArea())
        .confirmationDialog("Erase every stake and sealed road?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MoorVellum.space(2)) {
                Text("The waymap stays on this device. One stake a day. A drag writes one road.")
                    .vellumText(.body)
                figureRow(title: "Stakes", value: WaymapFigures.count(watch.graph.stakes.count))
                figureRow(title: "Chosen roads", value: WaymapFigures.count(watch.graph.committedRoads.count))
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var actions: some View {
        VStack(spacing: MoorVellum.space(1)) {
            Button {
                openURL(CairnCourier.contactURL)
            } label: {
                Text("Contact")
                    .vellumText(.body)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                watch.reopenOnboarding()
                dismiss()
            } label: {
                Text("Re-run onboarding")
                    .vellumText(.body)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .vellumText(.body)
                    .foregroundStyle(MoorVellum.Palette.danger)
                    .frame(maxWidth: .infinity, minHeight: MoorVellum.tap)
                    .background(MoorVellum.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(resetBusy)
        }
    }

    private var errorState: some View {
        VellumVacancy(
            image: "gds_EmptyList",
            headline: "The marks could not be sealed.",
            line: "Retry, or reset if the waymap stays torn.",
            actionTitle: "Retry"
        ) {
            Task { await watch.retryLoad() }
        }
    }

    private func figureRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .vellumText(.body)
                .lineLimit(1)
            Spacer(minLength: MoorVellum.space(1))
            Text(value)
                .vellumText(.figure)
                .layoutPriority(1)
        }
        .frame(minHeight: MoorVellum.tap)
    }

    private func resetAll() async {
        resetBusy = true
        await watch.resetAllData()
        resetBusy = false
        dismiss()
    }
}
