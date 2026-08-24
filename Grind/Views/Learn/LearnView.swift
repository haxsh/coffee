import SwiftUI
import CoffeeKit

/// v1 ships the concept library rather than a course, and says so plainly.
///
/// Lessons are a writing project with their own timeline and their own required
/// expertise (OQ-7); shipping empty course shells would be worse than shipping
/// none. The concepts are what the diagnosis engine actually links to, so this is
/// the part of Learn that carries real weight today.
struct LearnView: View {
    @Environment(BrewFlow.self) private var flow
    @Environment(AppModel.self) private var model
    @State private var search = ""

    private var results: [Concept] {
        guard !search.isEmpty else { return Concepts.alphabetical }
        return Concepts.alphabetical.filter {
            $0.term.localizedCaseInsensitiveContains(search)
                || $0.shortDefinition.localizedCaseInsensitiveContains(search)
        }
    }

    /// Concepts the user has actually met through a diagnosis. Makes the ambient
    /// path visible, and it's satisfying to watch fill up.
    private var metConceptIDs: Set<String> {
        Set(model.data.brews.compactMap { $0.diagnosis?.conceptID })
    }

    var body: some View {
        NavigationStack {
            List {
                if !metConceptIDs.isEmpty && search.isEmpty {
                    Section("Concepts you've met") {
                        ForEach(Concepts.alphabetical.filter { metConceptIDs.contains($0.id) }) { concept in
                            row(concept, met: true)
                        }
                    }
                }
                Section(search.isEmpty ? "All concepts" : "Results") {
                    ForEach(results) { concept in
                        row(concept, met: metConceptIDs.contains(concept.id))
                    }
                }
            }
            .searchable(text: $search, prompt: "Search concepts")
            .navigationTitle("Learn")
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
        }
    }

    private func row(_ concept: Concept, met: Bool) -> some View {
        Button {
            flow.showConcept(concept.id)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(met ? Theme.water : Theme.line)
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(concept.term).font(.headline).foregroundStyle(Theme.ink)
                    Text(concept.shortDefinition)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// One record, one presentation, many entry points — a recipe step, a diagnosis,
/// a tasting descriptor and the library all open exactly this. Fully offline and
/// instant: there is never a loading state in the one place a user asked for help.
struct ConceptCardSheet: View {
    @Environment(BrewFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss
    let concept: Concept

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(concept.shortDefinition)
                        .font(.title3.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(concept.card)
                        .font(.body)
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if !concept.relatedConceptIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related").sectionLabel()
                            ForEach(concept.relatedConceptIDs, id: \.self) { id in
                                if let related = Concepts.concept(id: id) {
                                    Button {
                                        flow.conceptID = related.id
                                    } label: {
                                        HStack {
                                            Text(related.term).foregroundStyle(Theme.water)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Theme.faint)
                                        }
                                        .frame(minHeight: 44)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle(concept.term)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
