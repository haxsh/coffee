import SwiftUI
import CoffeeKit

/// The hero screen. If this isn't right, nothing else counts.
///
/// Design context: wet hands, steam, a bright kitchen, a kettle in one hand, and
/// roughly ninety seconds of divided attention. Every decision here follows from
/// that sentence:
///
/// - **Taps only, and big ones.** Both controls are ≥ 88pt. No swipe gestures —
///   wet fingers don't swipe reliably, and a mis-swipe costs the brew.
/// - **The cumulative water target is the second-largest thing on screen**,
///   because it's what the scale reads. The user never adds pours together.
/// - **Runnable without looking**: every step change is a sound and a haptic.
/// - **No modal alerts, ever.** An overrun turns amber and says nothing.
/// - **Auto-advances into the log**, so there's no finish button to forget —
///   forgetting one means a lost brew and a broken loop.
struct GuidedBrewView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let session: BrewSession
    @State private var showingCancelConfirm = false

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                clock
                waterTarget
                Spacer(minLength: 8)
                instruction
                Spacer(minLength: 8)
                stepDots
                nextUp
                controls
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .onAppear { session.start() }
        .confirmationDialog("Discard this brew?", isPresented: $showingCancelConfirm, titleVisibility: .visible) {
            Button("Discard brew", role: .destructive) {
                session.cancel()
                flow.session = nil
            }
            Button("Keep brewing", role: .cancel) {}
        } message: {
            Text("The timer stops and nothing is saved.")
        }
        .onChange(of: session.isComplete) { _, complete in
            guard complete else { return }
            // Straight into the log — the taste memory is gone in ten minutes.
            let brew = session.makeBrew()
            model.addBrew(brew)
            flow.session = nil
            flow.brewToLog = brew
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Button {
                showingCancelConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Discard brew")

            Spacer()

            VStack(spacing: 2) {
                Text(session.recipe.name)
                    .font(.subheadline.weight(.semibold))
                if let bean = session.beanName {
                    Text(bean).font(.caption).foregroundStyle(Theme.muted)
                }
            }

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var clock: some View {
        Text(BrewMath.formatSeconds(Int(session.elapsed)))
            .font(Theme.clock(size: 88))
            .foregroundStyle(session.isPaused ? Theme.muted : Theme.ink)
            .contentTransition(.numericText())
            .accessibilityLabel("Elapsed \(Int(session.elapsed)) seconds")
            .accessibilityAddTraits(.updatesFrequently)
    }

    /// The number that matches the scale. Cumulative, always.
    private var waterTarget: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", session.currentTarget))
                    .font(Theme.clock(size: 46))
                    .foregroundStyle(Theme.water)
                    .contentTransition(.numericText())
                Text("/ \(BrewMath.formatGrams(session.totalWater))")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.muted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule()
                        .fill(session.isOverrunning ? Theme.heat : Theme.water)
                        .frame(width: geo.size.width * session.waterProgress)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: session.waterProgress)
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Water target \(Int(session.currentTarget)) of \(Int(session.totalWater)) grams")
    }

    private var instruction: some View {
        VStack(spacing: 12) {
            Text(session.currentStep?.instruction ?? "Let it draw down.")
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)

            // Learning arrives mid-brew without costing the brew: the sheet opens
            // over a still-running timer and dismisses back to exactly here.
            if let conceptID = session.currentStep?.conceptID,
               let concept = Concepts.concept(id: conceptID) {
                Button {
                    flow.showConcept(conceptID)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                        Text(concept.term).underline()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.water)
                    .frame(minHeight: 44)
                }
                .accessibilityHint("Opens an explanation. The timer keeps running.")
            }
        }
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(session.steps.enumerated()), id: \.element.id) { index, _ in
                Capsule()
                    .fill(index <= session.stepIndex ? Theme.water : Theme.line)
                    .frame(height: 4)
            }
        }
        .padding(.bottom, 10)
        .accessibilityElement()
        .accessibilityLabel("Step \(session.stepIndex + 1) of \(session.stepCount)")
    }

    /// Removes the surprise, and lets the user pre-position the kettle.
    private var nextUp: some View {
        Group {
            if let next = session.nextStep {
                Text("Next: \(next.instruction)")
                    .font(.footnote)
                    .foregroundStyle(Theme.faint)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text(session.isOverrunning ? "Running long — finish when it's done." : "Last step.")
                    .font(.footnote)
                    .foregroundStyle(session.isOverrunning ? Theme.heat : Theme.faint)
            }
        }
        .frame(minHeight: 36)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                controlButton(
                    title: session.isPaused ? "Resume" : "Pause",
                    icon: session.isPaused ? "play.fill" : "pause.fill",
                    tint: Theme.surfaceAlt,
                    foreground: Theme.ink
                ) {
                    session.togglePause()
                }

                controlButton(
                    title: session.nextStep == nil ? "Finish" : "Next",
                    icon: session.nextStep == nil ? "checkmark" : "forward.fill",
                    tint: Theme.water,
                    foreground: .white
                ) {
                    session.advance()
                }
            }

            Button("Add 15 seconds") {
                session.addTime()
            }
            .font(.subheadline)
            .foregroundStyle(Theme.muted)
            .frame(minHeight: 44)
        }
    }

    /// 88pt minimum: this is the one screen where a mis-tap costs the cup.
    private func controlButton(
        title: String,
        icon: String,
        tint: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22, weight: .semibold))
                Text(title).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
