import SwiftUI
import UIKit
import CoffeeKit

/// The most fragile screen in the product, and the one competing directly with
/// "I want to drink my coffee."
///
/// Hard constraint: **median completion under 30 seconds.** Every design decision
/// here is subordinate to that number, because everything downstream — diagnosis,
/// the journal, the widgets, the entire loop — assumes this got filled in.
///
/// Consequences, all deliberate:
/// - Rating, taste axis and body axis are three taps, above the fold, no scrolling.
/// - **Only the rating is required.** A brew logged with just a rating is valid.
/// - The recorded actuals are collapsed behind one summary line; most users never
///   open it.
/// - No free-text field above the fold. A text box reads as homework.
/// - Dismissing saves what's there. A partial log beats a lost one.
struct LogBrewView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss

    let brew: Brew

    @State private var rating = 4
    @State private var extraction = 0
    @State private var strength = 0
    @State private var descriptors: Set<Descriptor> = []
    @State private var note = ""
    @State private var showingActuals = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How was it?").sectionLabel()
                        RatingControl(rating: $rating)
                    }

                    AxisPicker(
                        title: "Taste",
                        lowLabel: "Sour",
                        centreLabel: "Balanced",
                        highLabel: "Bitter",
                        value: $extraction
                    )

                    AxisPicker(
                        title: "Body",
                        lowLabel: "Thin",
                        centreLabel: "Just right",
                        highLabel: "Heavy",
                        tinted: false,
                        value: $strength
                    )

                    descriptorChips
                    actualsSummary
                    noteField
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("Log this brew")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button("Save & see what to change") { save() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.bar)
            }
        }
        // Dismissing the sheet still saves. Losing a log loses the loop.
        .onDisappear {
            guard !saved else { return }
            persist()
        }
    }

    private var descriptorChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Anything else?").sectionLabel()
                Text("optional · up to 3")
                    .font(.caption2)
                    .foregroundStyle(Theme.faint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Descriptor.allCases, id: \.self) { descriptor in
                        chip(descriptor)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func chip(_ descriptor: Descriptor) -> some View {
        let selected = descriptors.contains(descriptor)
        return Button {
            toggle(descriptor)
        } label: {
            Text(descriptor.label)
                .font(.subheadline)
                .foregroundStyle(selected ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .background(selected ? Theme.water : Theme.surfaceAlt, in: Capsule())
        }
        .buttonStyle(.plain)
        // Long-press teaches the vocabulary without spending a tap on it.
        .contextMenu {
            if let conceptID = descriptor.conceptID,
               let concept = Concepts.concept(id: conceptID) {
                Button("What does \(concept.term.lowercased()) mean?") {
                    flow.showConcept(conceptID)
                }
            }
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var actualsSummary: some View {
        DisclosureGroup(isExpanded: $showingActuals) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(detailRows, id: \.0) { row in
                    HStack {
                        Text(row.0).foregroundStyle(Theme.muted)
                        Spacer()
                        Text(row.1).monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
            .padding(.top, 8)
        } label: {
            Text(summaryLine)
                .font(.subheadline.monospaced())
                .foregroundStyle(Theme.muted)
        }
        .tint(Theme.muted)
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").sectionLabel()
            TextField("Optional", text: $note, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Data

    private var summaryLine: String {
        var parts = [
            BrewMath.formatGrams(brew.dose),
            BrewMath.formatRatio(brew.ratio)
        ]
        if let seconds = brew.actualTotalSeconds {
            parts.append(BrewMath.formatSeconds(seconds))
        }
        if let setting = brew.grinderSetting,
           let grinder = model.data.grinders.first(where: { $0.id == brew.grinderID }) {
            parts.append(grinder.format(setting))
        }
        return parts.joined(separator: " · ")
    }

    private var detailRows: [(String, String)] {
        var rows: [(String, String)] = [
            ("Dose", BrewMath.formatGrams(brew.dose)),
            ("Ratio", BrewMath.formatRatio(brew.ratio)),
            ("Water", BrewMath.formatGrams(brew.totalWater))
        ]
        if let temp = brew.params[.waterTemp] {
            rows.append(("Water temp", "\(Int(temp)) °C"))
        }
        if let seconds = brew.actualTotalSeconds {
            rows.append(("Total time", BrewMath.formatSeconds(seconds)))
        }
        if let days = brew.beanRestDays {
            rows.append(("Bean rest", "\(days) days"))
        }
        return rows
    }

    private func toggle(_ descriptor: Descriptor) {
        if descriptors.contains(descriptor) {
            descriptors.remove(descriptor)
        } else if descriptors.count < 3 {
            descriptors.insert(descriptor)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    @discardableResult
    private func persist() -> Brew {
        var updated = brew
        updated.taste = TasteRecord(
            rating: rating,
            extraction: extraction,
            strength: strength,
            descriptors: Array(descriptors),
            note: note.isEmpty ? nil : note
        )
        updated.diagnosis = model.diagnose(updated)
        model.updateBrew(updated)
        return updated
    }

    private func save() {
        saved = true
        let updated = persist()
        dismiss()
        // Handing straight to Next Time is the whole point of the screen.
        flow.brewToDiagnose = updated
    }
}
