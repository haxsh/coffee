import Foundation

/// Every tunable number the engine uses, in one auditable place.
///
/// These are a designer's draft (OQ-1). Keeping them here — rather than scattered
/// as literals through the rules — is what makes it possible to hand this file to a
/// roaster and have them argue with it line by line.
public struct DiagnosisThresholds: Hashable, Sendable {
    /// Below this, water temperature is the dominant cause of under-extraction and
    /// should be fixed before anyone touches the grinder.
    public var coolWaterCelsius: Double
    /// How far past the method's expected maximum counts as a slow drawdown.
    public var drawdownOverrunSeconds: Int
    /// Ratio move for one strength adjustment, in 1:N.
    public var ratioStep: Double
    /// Steep-time move for one immersion adjustment.
    public var steepStepSeconds: Double
    /// How much to move water temperature when grind isn't available as a lever.
    public var tempStepCelsius: Double
    /// Don't suggest a temperature change that would land within this of the
    /// method's limit — a lever with nowhere left to go is not advice.
    public var tempHeadroomCelsius: Double

    public init(
        coolWaterCelsius: Double = 88,
        drawdownOverrunSeconds: Int = 15,
        ratioStep: Double = 1,
        steepStepSeconds: Double = 45,
        tempStepCelsius: Double = 3,
        tempHeadroomCelsius: Double = 2
    ) {
        self.coolWaterCelsius = coolWaterCelsius
        self.drawdownOverrunSeconds = drawdownOverrunSeconds
        self.ratioStep = ratioStep
        self.steepStepSeconds = steepStepSeconds
        self.tempStepCelsius = tempStepCelsius
        self.tempHeadroomCelsius = tempHeadroomCelsius
    }

    public static let `default` = DiagnosisThresholds()
}

public struct DiagnosisInput: Sendable {
    public var taste: TasteRecord
    public var method: BrewMethod
    public var params: BrewParameters
    public var actualTotalSeconds: Int?
    public var beanFreshness: Freshness?
    public var beanRestDays: Int?
    /// What the user can actually change about their grind. Modelled as a
    /// capability rather than assumed — see `GrindControl`.
    public var grindControl: GrindControl
    public var waterSource: WaterSource
    public var withMilk: Bool
    /// Whether the water explanation has already been given once. The water rule
    /// is a gate, not a verdict: it interrupts once and then steps out of the way.
    public var hasSeenWaterAdvice: Bool

    public init(
        taste: TasteRecord,
        method: BrewMethod,
        params: BrewParameters,
        actualTotalSeconds: Int? = nil,
        beanFreshness: Freshness? = nil,
        beanRestDays: Int? = nil,
        grindControl: GrindControl = .uncalibrated,
        waterSource: WaterSource = .unknown,
        withMilk: Bool = false,
        hasSeenWaterAdvice: Bool = false
    ) {
        self.taste = taste
        self.method = method
        self.params = params
        self.actualTotalSeconds = actualTotalSeconds
        self.beanFreshness = beanFreshness
        self.beanRestDays = beanRestDays
        self.grindControl = grindControl
        self.waterSource = waterSource
        self.withMilk = withMilk
        self.hasSeenWaterAdvice = hasSeenWaterAdvice
    }

    /// The extraction axis, or nil when milk has made it unreadable.
    var extraction: Int? { withMilk ? nil : taste.extraction }
    var strength: Int { taste.strength }
    /// The milk axis, or nil for a black cup.
    var milkCharacter: Int? { withMilk ? taste.milkCharacter : nil }
}

/// Maps a taste record to one hypothesis and exactly one change.
///
/// The model separates two things beginners constantly conflate:
///
/// - **Extraction** — how much was pulled out of the grounds. Too little tastes
///   sour and thin-finished; too much tastes bitter and drying.
/// - **Strength** — how much coffee is dissolved in the water. Too little is
///   watery; too much is muddy. Moved by ratio.
///
/// Four things gate the table before any of that applies:
///
/// 1. **Tier.** A `.guided` method returns notes about the brewer; a `.reference`
///    method returns nothing. Enforced by the return type, not by convention.
/// 2. **Milk.** Milk makes the extraction axis unreadable, so the log asks a
///    different question and the engine runs a different table — it does not
///    silently reinterpret an answer the user gave to another question.
/// 3. **Water.** Straight RO can stall extraction whatever the grinder does. Said
///    once, then it gets out of the way.
/// 4. **Grind control.** "Grind finer" is not advice to someone who buys
///    pre-ground. Where grind isn't available the engine reaches for temperature,
///    time and ratio — and, when those run out, says honestly that the grind they
///    have suits a different brewer.
///
/// Which lever comes *first* is method-specific. Pour-over is grind-dominant
/// because grind sets flow rate; immersion is time-dominant because the water
/// isn't going anywhere. That difference is the whole reason the tables are
/// separate rather than parameterised.
///
/// No confidence scores, no regression, no model. A transparent table a coffee
/// professional can read and correct is worth more than something nobody can
/// debug — and it can be reviewed before launch, which a model can't.
public struct DiagnosisEngine: Sendable {
    public let thresholds: DiagnosisThresholds

    public init(thresholds: DiagnosisThresholds = .default) {
        self.thresholds = thresholds
    }

    // MARK: - Entry point

    public func evaluate(_ input: DiagnosisInput) -> DiagnosisOutcome {
        switch input.method.supportTier {
        case .reference:
            return .unsupported
        case .guided:
            return .methodNotes(MethodNotes.forMethod(input.method))
        case .full:
            return .diagnosis(runTable(input))
        }
    }

    /// Convenience for callers that already know they're on a tier 1 method.
    public func diagnose(_ input: DiagnosisInput) -> Diagnosis? {
        evaluate(input).diagnosis
    }

    // MARK: - The table

    private func runTable(_ input: DiagnosisInput) -> Diagnosis {
        if let result = beanRules(input) { return result }
        if let result = waterRule(input) { return result }

        if input.withMilk {
            if let result = milkRules(input) { return result }
        } else {
            if let result = extractionRules(input) { return result }
        }

        if let result = strengthRules(input) { return result }
        return closingRules(input)
    }

    // MARK: - 1–2 · Rule out the bean before blaming the brewer

    private func beanRules(_ input: DiagnosisInput) -> Diagnosis? {
        // 1 — still degassing. Diagnosing this teaches something untrue about technique.
        if input.beanFreshness == .resting, !input.taste.isBalanced(withMilk: input.withMilk) {
            let days = input.beanRestDays.map(String.init) ?? "a few"
            return Diagnosis(
                ruleID: 1,
                verdict: "Too soon to tell — this coffee is still degassing.",
                adjustment: .none,
                explanation: "At \(days) days off roast this bag is still pushing out CO₂, which disrupts extraction and makes results jump around. Give it two or three more days and brew it exactly the same way so you have something to compare.",
                conceptID: "degassing"
            )
        }

        // 2 — past it. No brew variable recovers stale coffee.
        if input.beanFreshness == .stale,
           !Set(input.taste.descriptors).isDisjoint(with: Descriptor.stalingSignals) {
            return Diagnosis(
                ruleID: 2,
                verdict: "Nothing to fix here — this bag is past its best.",
                adjustment: .none,
                explanation: "Flat, papery notes on an older bag are staling, not a brewing mistake. No grind or ratio change brings that back. Note it and move to a fresher coffee.",
                conceptID: "staling"
            )
        }

        return nil
    }

    // MARK: - 3 · Water, once

    /// A gate rather than a verdict. Without the "already seen" condition, an RO
    /// user who is *also* genuinely grinding too coarse would be told "it's your
    /// water" after every brew, and the loop would never advance past its first
    /// turn. It interrupts once, explains the fix, and steps aside.
    private func waterRule(_ input: DiagnosisInput) -> Diagnosis? {
        guard input.waterSource.mayStallExtraction, !input.hasSeenWaterAdvice else { return nil }

        let readsThin = input.strength <= -1
        let readsSour = (input.extraction ?? 0) <= -1
        let readsFlat = (input.milkCharacter ?? 0) >= 1
        guard readsThin || readsSour || readsFlat else { return nil }

        return Diagnosis(
            ruleID: 3,
            verdict: "This one's probably your water, not your grind.",
            adjustment: Adjustment(
                kind: .blendWater,
                headline: "Mix in some tap water",
                detail: "About 70% RO to 30% tap"
            ),
            explanation: "RO water has had almost all its minerals stripped out, and those minerals are what pull flavour out of the grounds. Try roughly a 70:30 blend with tap and brew it exactly the same way — it costs nothing, and it's usually the difference.",
            conceptID: "water-chemistry"
        )
    }

    // MARK: - 4–7 / 20–23 · Extraction, black coffee

    private func extractionRules(_ input: DiagnosisInput) -> Diagnosis? {
        guard let extraction = input.extraction else { return nil }

        // Immersion-specific: grit in the cup is about fines and the plunge, not
        // about extraction, so it is diagnosed on its own terms and before the
        // extraction axis gets a say.
        if input.method.id == BuiltInContent.frenchPress.id,
           !Set(input.taste.descriptors).isDisjoint(with: Descriptor.siltSignals) {
            return Diagnosis(
                ruleID: 20,
                verdict: "That grit is fines, not over-extraction.",
                adjustment: grindAdjustment(finer: false, input: input, fallbackHeadline: "Press more gently"),
                explanation: "A metal mesh lets the powder-fine particles straight through, and pressing the plunger hard forces more of them past it. Go a step coarser if you can, and stop the plunger at the surface rather than driving it down.",
                conceptID: "fines"
            )
        }

        if extraction <= -1 {
            // 4 — water far below range swamps grind, so it goes first. This must be
            // checked before the generic rule or it can never fire at all.
            if let temp = input.params[.waterTemp], temp < thresholds.coolWaterCelsius,
               let hotter = temperatureAdjustment(input, warmer: true) {
                return Diagnosis(
                    ruleID: 4,
                    verdict: "Under-extracted — but your water was the likely culprit, not your grind.",
                    adjustment: hotter,
                    explanation: "Cooler water dissolves the sweet, heavier compounds much more slowly than the bright acidic ones, so the cup lands sour. Fix the temperature before touching anything else — it's the bigger lever here.",
                    conceptID: "water-temperature"
                )
            }
            return underExtracted(input)
        }

        if extraction >= 1 {
            return overExtracted(input)
        }

        return nil
    }

    /// Pour-over reaches for grind first; immersion reaches for time first. That
    /// ordering *is* the difference between the two rule tables.
    private func underExtracted(_ input: DiagnosisInput) -> Diagnosis {
        if isImmersion(input.method), let longer = steepAdjustment(input, longer: true) {
            return Diagnosis(
                ruleID: 21,
                verdict: verdictForUnder(input),
                adjustment: longer,
                explanation: "In an immersion brew the water isn't going anywhere, so time is doing most of the work. Another minute in contact pulls out more of the sweetness before you touch the grinder.",
                conceptID: "immersion"
            )
        }
        return Diagnosis(
            ruleID: 5,
            verdict: verdictForUnder(input),
            adjustment: grindAdjustment(finer: true, input: input),
            explanation: "Coarser grounds give the water less surface to work on, so it pulls out the bright, acidic compounds and never gets to the sweet ones. Grinding finer gives it more to hold on to.",
            conceptID: "under-extraction"
        )
    }

    private func overExtracted(_ input: DiagnosisInput) -> Diagnosis {
        if isImmersion(input.method), let shorter = steepAdjustment(input, longer: false) {
            return Diagnosis(
                ruleID: 22,
                verdict: verdictForOver(input),
                adjustment: shorter,
                explanation: "It sat in the water long enough to start pulling out the bitter, drying compounds behind the sweetness. Take a minute off before changing anything else — in immersion, time is the first thing to reach for.",
                conceptID: "immersion"
            )
        }

        // 6 — over-extraction with an observable mechanism. Naming the drawdown
        // makes the advice checkable next time, which grind advice alone isn't.
        if let actual = input.actualTotalSeconds,
           actual > input.method.expectedTotalSeconds.upperBound + thresholds.drawdownOverrunSeconds {
            return Diagnosis(
                ruleID: 6,
                verdict: "Over-extracted — and your drawdown ran long.",
                adjustment: grindAdjustment(finer: false, input: input),
                explanation: "This brew took \(BrewMath.formatSeconds(actual)) against an expected \(BrewMath.formatSeconds(input.method.expectedTotalSeconds.upperBound)). The water sat on the grounds too long and kept pulling out the bitter, drying compounds. Going coarser speeds the drawdown and shortens contact time.",
                conceptID: "drawdown"
            )
        }

        return Diagnosis(
            ruleID: 7,
            verdict: verdictForOver(input),
            adjustment: grindAdjustment(finer: false, input: input),
            explanation: "Finer grounds give water more surface and more time, and past a point it starts pulling out the bitter, drying compounds behind the sweetness. Going coarser pulls it back.",
            conceptID: "over-extraction"
        )
    }

    // MARK: - 30–32 · Milk

    /// Milk removes an axis rather than muting a rule.
    ///
    /// Fat and protein bind to the compounds that read as acidity and bitterness,
    /// so the log asks harsh ↔ smooth ↔ flat instead of sour ↔ bitter — and these
    /// rules read that answer. Reinterpreting a sour/bitter answer the user never
    /// gave would be the actual misdiagnosis the milk flag exists to prevent.
    private func milkRules(_ input: DiagnosisInput) -> Diagnosis? {
        guard let character = input.milkCharacter else { return nil }

        // 30 — harsh or burnt: over-extraction or too dark a roast, showing through
        // the milk. The advice is coarser than a black-coffee diagnosis, honestly so.
        if character <= -1 {
            let adjustment = isImmersion(input.method)
                ? (steepAdjustment(input, longer: false) ?? grindAdjustment(finer: false, input: input))
                : (temperatureAdjustment(input, warmer: false) ?? grindAdjustment(finer: false, input: input))
            return Diagnosis(
                ruleID: 30,
                verdict: "Harsh through the milk — it's being pushed too far.",
                adjustment: adjustment,
                explanation: "Milk hides a lot, so when harshness still comes through it's usually real over-extraction or a very dark roast. Back off the heat or the contact time first; if it persists on the same beans, it's the roast, not the brew.",
                conceptID: "milk"
            )
        }

        // 31 — flat and washed out through milk: almost always under-strength
        // rather than under-extraction. Milk dilutes before it masks.
        if character >= 1 {
            return Diagnosis(
                ruleID: 31,
                verdict: "The milk is winning — there isn't enough coffee behind it.",
                adjustment: ratioAdjustment(stronger: true, input: input),
                explanation: "Flat and washed-out in a milk drink is nearly always strength rather than extraction. Make the coffee itself more concentrated before changing anything about how you brew it — or use a little less milk.",
                conceptID: "milk"
            )
        }

        return nil
    }

    // MARK: - 8–9 · Strength

    private func strengthRules(_ input: DiagnosisInput) -> Diagnosis? {
        // Only meaningful once the axis above it has come back clean.
        let axisIsFine = input.withMilk ? (input.milkCharacter == 0) : (input.extraction == 0)
        guard axisIsFine else { return nil }

        if input.strength <= -1 {
            return Diagnosis(
                ruleID: 8,
                verdict: "Nothing wrong with your extraction — the cup is just dilute.",
                adjustment: ratioAdjustment(stronger: true, input: input),
                explanation: "Watery without being sour means you pulled the right things out, just into too much water. Keep everything else the same and use less water — this is a strength problem, not an extraction one.",
                conceptID: "brew-ratio"
            )
        }

        if input.strength >= 1 {
            return Diagnosis(
                ruleID: 9,
                verdict: "Nothing wrong with your extraction — the cup is just too concentrated.",
                adjustment: ratioAdjustment(stronger: false, input: input),
                explanation: "Heavy and muddy without being bitter means the extraction landed, there's simply too much of it per sip. Keep the same grind and add water.",
                conceptID: "brew-ratio"
            )
        }

        return nil
    }

    // MARK: - 10–12 · Closing

    private func closingRules(_ input: DiagnosisInput) -> Diagnosis {
        let balanced = input.taste.isBalanced(withMilk: input.withMilk)

        if balanced, input.taste.rating >= 4 {
            return Diagnosis(
                ruleID: 10,
                verdict: "Balanced, and you liked it. This is your recipe now.",
                adjustment: .none,
                explanation: "Nothing to change. Save these numbers and brew them again tomorrow — repeating a good cup on purpose is the whole skill.",
                conceptID: nil
            )
        }

        if balanced {
            return Diagnosis(
                ruleID: 11,
                verdict: "Your brewing is dialled in — this is the coffee, not the technique.",
                adjustment: .none,
                explanation: "Balanced on both axes but still not enjoyable usually means the bean or the water, not the brew. Try a different coffee before changing anything about how you're making it.",
                conceptID: "water-chemistry"
            )
        }

        return Diagnosis(
            ruleID: 12,
            verdict: "Not enough to go on yet.",
            adjustment: .none,
            explanation: "Brew this one the same way once more so there's something to compare it against.",
            conceptID: nil
        )
    }

    // MARK: - Adjustment builders

    private func isImmersion(_ method: BrewMethod) -> Bool {
        method.param(.steepTime) != nil
    }

    /// Grind, when the user has grind to give.
    ///
    /// When they don't, this is where the engine stops repeating a lever they
    /// can't reach and falls back through the ones they can — temperature, then
    /// time, then, honestly, a different brewer.
    private func grindAdjustment(
        finer: Bool,
        input: DiagnosisInput,
        fallbackHeadline: String? = nil
    ) -> Adjustment {
        let kind: Adjustment.Kind = finer ? .grindFiner : .grindCoarser
        let headline = fallbackHeadline ?? (finer ? "Grind finer" : "Grind coarser")

        switch input.grindControl {
        case let .calibrated(grinder, current):
            let next = grinder.adjustedSetting(from: current, steps: finer ? -1 : 1)
            guard abs(next - current) > 0.001 else {
                // Already at the end of the dial: say so rather than repeating
                // advice the user physically cannot follow.
                return Adjustment(
                    kind: kind,
                    headline: headline,
                    detail: "You're already at the \(finer ? "finest" : "coarsest") setting on your \(grinder.displayName). Adjust your ratio instead, or try a different coffee."
                )
            }
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "\(grinder.format(current)) → \(grinder.format(next)) on your \(grinder.displayName)",
                paramKey: .grind,
                newValue: grinder.normalised(fromSetting: next),
                newGrinderSetting: next
            )

        case .uncalibrated:
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "One step \(finer ? "finer" : "coarser") than last time."
            )

        case .preGround:
            return preGroundAdjustment(finer: finer, input: input)
        }
    }

    /// The pre-ground path.
    ///
    /// Grind is the strongest lever in every table, and a large share of this
    /// market buys pre-ground. Rather than give them advice they can't act on, the
    /// engine spends the levers they do have — and when those run out, it says the
    /// true thing: the coffee they bought suits a different brewer.
    private func preGroundAdjustment(finer: Bool, input: DiagnosisInput) -> Adjustment {
        // Under-extracted → hotter or longer. Over-extracted → cooler or shorter.
        if isImmersion(input.method), let steep = steepAdjustment(input, longer: finer) {
            return steep
        }
        if let temp = temperatureAdjustment(input, warmer: finer) {
            return temp
        }
        if let method = suggestedMethod(finer: finer, input: input) {
            return Adjustment(
                kind: .tryDifferentMethod,
                headline: "Try a \(method.name)",
                detail: finer
                    ? "Pre-ground this coarse suits \(method.name) better than \(input.method.name)"
                    : "Pre-ground this fine suits \(method.name) better than \(input.method.name)",
                suggestedMethodID: method.id
            )
        }
        return Adjustment(
            kind: .none,
            headline: "You've run out of levers here",
            detail: "Without a grinder there's nothing left to change on this brewer. A different coffee, or a grinder, is the honest next step."
        )
    }

    /// A brewable method whose default grind sits on the side of the current one
    /// that the user needs — the concrete version of "your grind suits something
    /// else."
    private func suggestedMethod(finer: Bool, input: DiagnosisInput) -> BrewMethod? {
        let current = input.method.param(.grind)?.defaultValue ?? 50
        let candidates = BuiltInContent.brewableMethods.filter { method in
            guard method.id != input.method.id,
                  method.profile.worksWithPreGround,
                  let grind = method.param(.grind)?.defaultValue else { return false }
            // Under-extracting on pre-ground means the grind is too coarse for this
            // brewer — so point at a brewer that wants coarse coffee.
            return finer ? grind > current + 10 : grind < current - 10
        }
        return finer
            ? candidates.max { ($0.param(.grind)?.defaultValue ?? 0) < ($1.param(.grind)?.defaultValue ?? 0) }
            : candidates.min { ($0.param(.grind)?.defaultValue ?? 0) < ($1.param(.grind)?.defaultValue ?? 0) }
    }

    private func temperatureAdjustment(_ input: DiagnosisInput, warmer: Bool) -> Adjustment? {
        guard let def = input.method.param(.waterTemp),
              let current = input.params[.waterTemp] else { return nil }
        let step = warmer ? thresholds.tempStepCelsius : -thresholds.tempStepCelsius
        let next = def.clamp(current + step)
        // A lever with nowhere left to go is not advice.
        guard abs(next - current) >= thresholds.tempHeadroomCelsius else { return nil }

        return Adjustment(
            kind: warmer ? .hotterWater : .coolerWater,
            headline: warmer ? "Use hotter water" : "Use cooler water",
            detail: "\(Int(current.rounded())) °C → \(Int(next.rounded())) °C",
            paramKey: .waterTemp,
            newValue: next
        )
    }

    private func steepAdjustment(_ input: DiagnosisInput, longer: Bool) -> Adjustment? {
        guard let def = input.method.param(.steepTime),
              let current = input.params[.steepTime] else { return nil }
        let step = longer ? thresholds.steepStepSeconds : -thresholds.steepStepSeconds
        let next = def.clamp(current + step)
        guard abs(next - current) > 1 else { return nil }

        return Adjustment(
            kind: longer ? .steepLonger : .steepShorter,
            headline: longer ? "Steep longer" : "Steep less",
            detail: "\(BrewMath.formatSeconds(Int(current))) → \(BrewMath.formatSeconds(Int(next)))",
            paramKey: .steepTime,
            newValue: next
        )
    }

    private func ratioAdjustment(stronger: Bool, input: DiagnosisInput) -> Adjustment {
        let currentRatio = input.params.value(.ratio, default: 16)
        let dose = input.params.value(.dose, default: 15)
        let delta = stronger ? -thresholds.ratioStep : thresholds.ratioStep

        var nextRatio = currentRatio + delta
        if let def = input.method.param(.ratio) { nextRatio = def.clamp(nextRatio) }

        let kind: Adjustment.Kind = stronger ? .lessWater : .moreWater
        let headline = stronger ? "Use less water" : "Use more water"

        guard abs(nextRatio - currentRatio) > 0.001 else {
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "You're at the edge of the sensible range for this method — try a different dose instead."
            )
        }

        let currentWater = BrewMath.water(dose: dose, ratio: currentRatio)
        let nextWater = BrewMath.water(dose: dose, ratio: nextRatio)
        return Adjustment(
            kind: kind,
            headline: headline,
            detail: "\(BrewMath.formatRatio(currentRatio)) → \(BrewMath.formatRatio(nextRatio)) — "
                + "\(BrewMath.formatGrams(currentWater)) → \(BrewMath.formatGrams(nextWater)) for your \(BrewMath.formatGrams(dose)) dose",
            paramKey: .ratio,
            newValue: nextRatio
        )
    }

    // MARK: - Verdict copy

    private func verdictForUnder(_ input: DiagnosisInput) -> String {
        switch input.strength {
        case ..<0: return "Under-extracted — sour, and a bit thin with it."
        case 1...: return "Under-extracted — sour, and concentrated with it."
        default: return "Under-extracted — it came out sour."
        }
    }

    private func verdictForOver(_ input: DiagnosisInput) -> String {
        switch input.strength {
        case ..<0: return "Over-extracted — bitter, and thin with it."
        case 1...: return "Over-extracted — bitter and heavy."
        default: return "Over-extracted — it came out bitter and drying."
        }
    }
}

// MARK: - Closing the loop

extension DiagnosisEngine {
    /// Compares a brew against the one whose adjustment it applied.
    ///
    /// This is the payoff for the entire product, so it is also the place to be
    /// honest: when the change made things worse, say so and offer the way back.
    public static func loopOutcome(current: Brew, previous: Brew) -> LoopOutcome? {
        guard let now = current.taste?.rating,
              let before = previous.taste?.rating,
              let adjustment = previous.diagnosis?.adjustment,
              adjustment.isActionable
        else { return nil }

        let change = adjustment.pastTensePhrase
        if now > before { return .improved(from: before, to: now, change: change) }
        if now < before { return .worse(from: before, to: now, change: change) }
        return .unchanged(rating: now, change: change)
    }
}
