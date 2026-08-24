import SwiftUI
import UIKit
import CoffeeKit

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            List {
                // Gear is styled as a collection, not a settings list — a grinder
                // is something you own that changes the brewing maths, not a
                // preference you toggle.
                Section("My gear") {
                    ForEach(model.data.grinders) { grinder in
                        Button {
                            model.selectGrinder(grinder)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(grinder.displayName).foregroundStyle(Theme.ink)
                                    Text("Pour-over at \(grinder.format(grinder.pourOverAnchor))")
                                        .font(.caption)
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                if grinder.id == model.data.selectedGrinderID {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.water)
                                }
                            }
                        }
                    }
                    NavigationLink("Add a grinder") { GrinderSetupView() }
                }

                Section {
                    LabeledContent("Brews logged", value: "\(model.data.brews.count)")
                    LabeledContent("Coffees", value: "\(model.data.beans.count)")
                }

                // Never behind the paywall. Users trust a journal they can get out.
                Section {
                    Button("Export journal (CSV)") { export(csv: true) }
                    Button("Export everything (JSON)") { export(csv: false) }
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this device. Export works offline and is never restricted.")
                }

                Section {
                    LabeledContent("Version", value: "0.1 · design build")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showingShare) {
                if let exportURL { ShareSheet(items: [exportURL]) }
            }
        }
    }

    private func export(csv: Bool) {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent(csv ? "grind-journal.csv" : "grind-export.json")
        let data: Data? = csv ? model.exportCSV().data(using: .utf8) : model.exportJSON()
        guard let data, (try? data.write(to: url, options: .atomic)) != nil else { return }
        exportURL = url
        showingShare = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Calibration by anchoring: one question, no measuring, no burr-gap micrometry.
/// The setting you already use becomes the middle of the scale, and every recipe
/// translates into your units from there.
struct GrinderSetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Grinder = .baratzaEncore
    @State private var anchor: Double = 18

    var body: some View {
        Form {
            Section("Which grinder?") {
                Picker("Grinder", selection: $selected) {
                    ForEach(Grinder.knownGrinders) { Text($0.displayName).tag($0) }
                    Text("Something else").tag(Grinder.unknown)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Stepper(selected.format(anchor),
                        value: $anchor,
                        in: selected.minSetting...selected.maxSetting,
                        step: selected.settingType == .stepless ? 0.1 : 1)
                    .monospacedDigit()
            } header: {
                Text("What setting do you use for pour-over?")
            } footer: {
                Text("Roughly is fine. This is how \"grind finer\" becomes a number you can actually dial in.")
            }
        }
        .navigationTitle("Your grinder")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selected) { _, grinder in anchor = grinder.pourOverAnchor }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    var grinder = selected
                    grinder.pourOverAnchor = anchor
                    model.upsertGrinder(Grinder(
                        brand: grinder.brand,
                        model: grinder.model,
                        settingType: grinder.settingType,
                        minSetting: grinder.minSetting,
                        maxSetting: grinder.maxSetting,
                        pourOverAnchor: anchor,
                        adjustmentStep: grinder.adjustmentStep
                    ))
                    dismiss()
                }
            }
        }
    }
}
