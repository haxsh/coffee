import SwiftUI
import CoffeeKit

/// S30 — the most dangerous screen to get wrong, because it sits exactly where a
/// user expects Next Time and must not be mistaken for it.
///
/// It shares **no layout component** with `NextTimeView`, by design: no
/// single-change card, no from → to numbers, no "save this for next time". If a
/// tier 2 method's advice ever looked like a tier 1 diagnosis, the app would be
/// claiming a precision it doesn't have on the majority of its methods, and every
/// trust argument in the product brief would go with it.
struct MethodNotesView: View {
    @Environment(BrewFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss

    let notes: MethodNotes

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Naming the limit out loud is what buys the trust. A
                    // confident paragraph that turns out to be generic costs more
                    // than silence.
                    Text(notes.headline)
                        .font(.title3.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(notes.notes.enumerated()), id: \.offset) { _, note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title)
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            Text(note.body)
                                .font(.callout)
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            if let conceptID = note.conceptID,
                               let concept = Concepts.concept(id: conceptID) {
                                Button {
                                    flow.showConcept(conceptID)
                                } label: {
                                    Text(concept.term).underline()
                                        .font(.footnote)
                                        .foregroundStyle(Theme.water)
                                        .frame(minHeight: 44, alignment: .leading)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardBackground()
                    }

                    Text("Your brew is saved either way — you can see it in the journal.")
                        .font(.footnote)
                        .foregroundStyle(Theme.faint)
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("About this method")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                // "Got it", not "Save this for next time". There is nothing to
                // apply, and offering to apply it would be the lie.
                Button("Got it") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.muted))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
        }
    }
}
