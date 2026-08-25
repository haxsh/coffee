import SwiftUI
import UIKit
import CoffeeKit

/// The payoff. This is the screen the whole product exists to show.
///
/// One verdict in plain language, **one** change as the visual centre of the
/// screen in the user's own units, two sentences of why, and a way to refuse.
/// Never a ranked list — with options, every user picks the easiest one and two
/// variables move at once.
struct NextTimeView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let brew: Brew
    @State private var applied = false

    private var diagnosis: Diagnosis? { brew.diagnosis }
    private var outcome: LoopOutcome? { model.loopOutcome(for: brew) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let outcome { loopBanner(outcome) }

                    if let diagnosis {
                        Text(diagnosis.verdict)
                            .font(.title3.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)

                        if diagnosis.adjustment.isActionable {
                            adjustmentCard(diagnosis.adjustment)
                        } else {
                            noChangeCard(diagnosis.adjustment)
                        }

                        Text(diagnosis.explanation)
                            .font(.callout)
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        if let conceptID = diagnosis.conceptID,
                           let concept = Concepts.concept(id: conceptID) {
                            Button {
                                flow.showConcept(conceptID)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "book")
                                    Text("What is \(concept.term.lowercased())?").underline()
                                }
                                .font(.subheadline)
                                .foregroundStyle(Theme.water)
                                .frame(minHeight: 44)
                            }
                        }
                    } else {
                        Text("Log how it tasted to get a recommendation.")
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("Next time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let adjustment = diagnosis?.adjustment, adjustment.isActionable {
                    VStack(spacing: 6) {
                        Button(applied ? "Saved for next time" : "Save this for next time") {
                            model.applyAdjustment(adjustment, from: brew)
                            applied = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: applied ? Theme.target : Theme.water))
                        .disabled(applied)

                        // A recommendation you can't refuse isn't advice.
                        Button("Not this time") { dismiss() }
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .background(.bar)
                }
            }
        }
    }

    /// The moment the product proves itself — and the moment it has to be honest.
    /// When the change made things worse, this says so and offers the way back.
    private func loopBanner(_ outcome: LoopOutcome) -> some View {
        let isGood: Bool = {
            if case .improved = outcome { return true }
            return false
        }()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: isGood ? "checkmark.seal.fill" : "arrow.uturn.backward")
                Text(outcome.headline).font(.headline)
            }
            .foregroundStyle(isGood ? Theme.target : Theme.heat)

            Text(outcome.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isGood ? Theme.target : Theme.heat).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
    }

    /// The one change, as the visual centre of the screen.
    private func adjustmentCard(_ adjustment: Adjustment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The one change").sectionLabel()
            Text(adjustment.headline)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(tint(for: adjustment.kind))
            Text(adjustment.detail)
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private func noChangeCard(_ adjustment: Adjustment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(adjustment.headline)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.target)
            Text(adjustment.detail)
                .font(.callout)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    /// Colour encodes *which way the adjustment moves extraction*, so it teaches
    /// the same thing here as it does on the taste axis: water for the changes
    /// that pull extraction up out of sourness, heat for the ones that pull it
    /// back from bitterness. Ratio changes are neither, so they stay neutral.
    ///
    /// Exhaustive on purpose — a new lever should force a decision about what it
    /// means, not inherit a default.
    private func tint(for kind: Adjustment.Kind) -> Color {
        switch kind {
        case .grindFiner, .hotterWater, .steepLonger, .blendWater:
            return Theme.water
        case .grindCoarser, .coolerWater, .steepShorter:
            return Theme.heat
        case .lessWater, .moreWater, .tryDifferentMethod:
            return Theme.ink
        case .none:
            return Theme.target
        }
    }
}
