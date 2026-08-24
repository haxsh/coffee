import SwiftUI
import CoffeeKit

struct BeansListView: View {
    @Environment(AppModel.self) private var model
    @State private var addingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if model.data.beans.isEmpty {
                    EmptyStateView(
                        icon: "bag",
                        title: "Add the bag on your counter",
                        message: "A name and a roast date is enough. The roast date is what makes the advice you get after a brew more accurate.",
                        actionTitle: "Add coffee",
                        action: { addingNew = true }
                    )
                } else {
                    List {
                        Section("On the shelf") {
                            ForEach(model.activeBeans) { bean in
                                NavigationLink { BeanDetailView(bean: bean) } label: { row(bean) }
                            }
                        }
                        let archived = model.data.beans.filter(\.isArchived)
                        if !archived.isEmpty {
                            Section("Finished") {
                                ForEach(archived) { bean in
                                    NavigationLink { BeanDetailView(bean: bean) } label: { row(bean) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Beans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add coffee")
                }
            }
            .sheet(isPresented: $addingNew) { BeanEditorView(bean: nil) }
        }
    }

    private func row(_ bean: Bean) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bean.name).font(.headline)
            if !bean.displaySubtitle.isEmpty {
                Text(bean.displaySubtitle).font(.footnote).foregroundStyle(Theme.muted)
            }
            FreshnessBadge(freshness: bean.freshness(), restDays: bean.restDays())
        }
        .padding(.vertical, 2)
    }
}

struct BeanDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    let bean: Bean
    @State private var editing = false

    private var brews: [Brew] { model.brews(forBean: bean.id) }
    private var best: Brew? { model.bestBrew(forBean: bean.id) }

    var body: some View {
        List {
            Section {
                LabeledContent("Roaster", value: bean.roaster ?? "—")
                LabeledContent("Origin", value: bean.origin ?? "—")
                LabeledContent("Process", value: bean.process ?? "—")
                LabeledContent("Roast", value: bean.roastLevel.label)
                HStack {
                    Text("Freshness")
                    Spacer()
                    FreshnessBadge(freshness: bean.freshness(), restDays: bean.restDays())
                }
            }

            if let notes = bean.roasterNotes, !notes.isEmpty {
                Section("On the bag") { Text(notes).font(.callout) }
            }

            // Cheap to build, genuinely delightful: the exact numbers that made
            // your best cup from this bag.
            if let best, let taste = best.taste {
                Section("Your best cup from this bag") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= taste.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.water)
                            }
                        }
                        Text("\(BrewMath.formatGrams(best.dose)) · \(BrewMath.formatRatio(best.ratio)) · \(BrewMath.formatSeconds(best.actualTotalSeconds ?? 0))")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Brews with this coffee") {
                if brews.isEmpty {
                    Text("None yet.").foregroundStyle(Theme.muted)
                } else {
                    ForEach(brews) { brew in
                        NavigationLink { BrewDetailView(brew: brew) } label: { BrewRow(brew: brew) }
                    }
                }
            }
        }
        .navigationTitle(bean.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) { BeanEditorView(bean: bean) }
    }
}

/// Name and roast date are the only two fields that matter. Everything else is
/// optional and below the fold — a thirty-second job, not a data-entry form.
struct BeanEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let bean: Bean?

    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var process = ""
    @State private var roastLevel: RoastLevel = .light
    @State private var hasRoastDate = true
    @State private var roastDate = Date()
    @State private var bagWeight = "250"
    @State private var notes = ""
    @State private var isArchived = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Toggle("I know the roast date", isOn: $hasRoastDate)
                    if hasRoastDate {
                        DatePicker("Roasted", selection: $roastDate, in: ...Date(), displayedComponents: .date)
                    }
                    Picker("Roast level", selection: $roastLevel) {
                        ForEach(RoastLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                } footer: {
                    Text("Roast level changes how long a bag needs to rest, so it feeds the advice you get after a brew.")
                }

                Section("Details") {
                    TextField("Roaster", text: $roaster)
                    TextField("Origin", text: $origin)
                    TextField("Process", text: $process)
                    TextField("Bag weight (g)", text: $bagWeight).keyboardType(.numberPad)
                }

                Section("Notes on the bag") {
                    TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                }

                if bean != nil {
                    Section {
                        Toggle("Finished this bag", isOn: $isArchived)
                    }
                }
            }
            .navigationTitle(bean == nil ? "Add coffee" : "Edit coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded, let bean else { loaded = true; return }
        loaded = true
        name = bean.name
        roaster = bean.roaster ?? ""
        origin = bean.origin ?? ""
        process = bean.process ?? ""
        roastLevel = bean.roastLevel
        hasRoastDate = bean.roastDate != nil
        roastDate = bean.roastDate ?? Date()
        bagWeight = bean.bagWeightG.map { String(Int($0)) } ?? ""
        notes = bean.roasterNotes ?? ""
        isArchived = bean.isArchived
    }

    private func save() {
        var updated = bean ?? Bean(name: name)
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.roaster = roaster.isEmpty ? nil : roaster
        updated.origin = origin.isEmpty ? nil : origin
        updated.process = process.isEmpty ? nil : process
        updated.roastLevel = roastLevel
        updated.roastDate = hasRoastDate ? roastDate : nil
        updated.bagWeightG = Double(bagWeight)
        updated.roasterNotes = notes.isEmpty ? nil : notes
        updated.isArchived = isArchived
        model.upsertBean(updated)
        dismiss()
    }
}
