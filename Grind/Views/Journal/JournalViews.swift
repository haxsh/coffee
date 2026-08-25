import SwiftUI
import CoffeeKit

struct JournalListView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow

    private var grouped: [(Date, [Brew])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: model.brewsNewestFirst) {
            calendar.startOfDay(for: $0.startedAt)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.data.brews.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "Your brews will land here",
                        message: "Your first one is about four minutes away.",
                        actionTitle: "Start a brew",
                        action: { flow.selectedTab = .brew }
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.0) { day, brews in
                            Section(day.formatted(date: .abbreviated, time: .omitted)) {
                                ForEach(brews) { brew in
                                    NavigationLink { BrewDetailView(brew: brew) } label: { BrewRow(brew: brew) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Journal")
        }
    }
}

struct BrewRow: View {
    @Environment(AppModel.self) private var model
    let brew: Brew

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(model.recipe(id: brew.recipeID)?.name ?? "Freestyle brew")
                    .font(.headline)
                Spacer()
                if let rating = brew.taste?.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.water)
                        }
                    }
                } else {
                    Text("not logged").font(.caption2).foregroundStyle(Theme.faint)
                }
            }
            HStack(spacing: 8) {
                if let bean = model.bean(id: brew.beanID) {
                    Text(bean.name).lineLimit(1)
                }
                Text("\(BrewMath.formatGrams(brew.dose)) · \(BrewMath.formatRatio(brew.ratio))")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)

            if let adjustment = brew.diagnosis?.adjustment, adjustment.isActionable {
                Text(adjustment.headline)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.water)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Planned versus actual, side by side. This is where users discover they don't
/// execute what they plan — which is usually the real finding.
struct BrewDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    let brew: Brew

    private var drift: [BrewParamKey] {
        brew.plannedParams.changedKeys(comparedTo: brew.params)
    }

    var body: some View {
        List {
            if let taste = brew.taste {
                Section("How it tasted") {
                    LabeledContent("Rating", value: String(repeating: "★", count: taste.rating))
                    if brew.withMilk {
                        LabeledContent("Taste", value: axisLabel(taste.milkCharacter, low: "Harsh", high: "Flat"))
                        LabeledContent("Milk", value: "Yes")
                    } else {
                        LabeledContent("Taste", value: axisLabel(taste.extraction, low: "Sour", high: "Bitter"))
                    }
                    LabeledContent("Body", value: axisLabel(taste.strength, low: "Thin", high: "Heavy"))
                    if !taste.descriptors.isEmpty {
                        LabeledContent("Notes", value: taste.descriptors.map(\.label).joined(separator: ", "))
                    }
                    if let note = taste.note { Text(note).font(.callout) }
                }
            }

            if brew.diagnosis == nil,
               let method = BuiltInContent.method(id: brew.methodID),
               method.supportTier == .guided {
                Section("What we said") {
                    Text(MethodNotes.forMethod(method).headline)
                        .font(.callout)
                        .foregroundStyle(Theme.muted)
                    Button("See the notes for this method") {
                        flow.methodNotes = MethodNotes.forMethod(method)
                    }
                }
            }

            if let diagnosis = brew.diagnosis {
                Section("What we said") {
                    Text(diagnosis.verdict).font(.callout)
                    if diagnosis.adjustment.isActionable {
                        LabeledContent(diagnosis.adjustment.headline, value: diagnosis.adjustment.detail)
                            .font(.callout)
                    }
                    if let conceptID = diagnosis.conceptID, let concept = Concepts.concept(id: conceptID) {
                        Button("Read: \(concept.term)") { flow.showConcept(conceptID) }
                    }
                    Text("Rule \(diagnosis.ruleID)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(Theme.faint)
                }
            }

            Section("Planned vs actual") {
                row("Dose", planned: brew.plannedParams[.dose], actual: brew.params[.dose], format: BrewMath.formatGrams)
                row("Ratio", planned: brew.plannedParams[.ratio], actual: brew.params[.ratio], format: BrewMath.formatRatio)
                row("Water temp", planned: brew.plannedParams[.waterTemp], actual: brew.params[.waterTemp]) { "\(Int($0)) °C" }
                if let seconds = brew.actualTotalSeconds {
                    LabeledContent("Total time", value: BrewMath.formatSeconds(seconds))
                }
                if let setting = brew.grinderSetting,
                   let grinder = model.data.grinders.first(where: { $0.id == brew.grinderID }) {
                    LabeledContent("Grind", value: grinder.format(setting))
                }
            }

            if !drift.isEmpty {
                Section {
                    Text("You brewed this differently from the recipe: \(drift.map(\.rawValue).joined(separator: ", ")).")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .navigationTitle(brew.startedAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, planned: Double?, actual: Double?, format: (Double) -> String) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let planned, let actual, abs(planned - actual) > 0.001 {
                Text(format(planned)).foregroundStyle(Theme.faint).strikethrough()
                Text(format(actual)).foregroundStyle(Theme.heat)
            } else if let actual {
                Text(format(actual)).foregroundStyle(Theme.muted)
            } else {
                Text("—").foregroundStyle(Theme.faint)
            }
        }
        .monospacedDigit()
    }

    private func axisLabel(_ value: Int, low: String, high: String) -> String {
        switch value {
        case -2: return "Very \(low.lowercased())"
        case -1: return "Slightly \(low.lowercased())"
        case 0: return "Balanced"
        case 1: return "Slightly \(high.lowercased())"
        default: return "Very \(high.lowercased())"
        }
    }
}
