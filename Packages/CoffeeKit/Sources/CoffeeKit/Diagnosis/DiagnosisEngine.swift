import Foundation

/// Every tunable number the engine uses, in one auditable place.
///
/// These are a designer's draft (OQ-1). Keeping them here — rather than scattered
/// as literals through the rules — is what makes it possible to hand this file to
/// a roaster and have them argue with it line by line.
public struct DiagnosisThresholds: Hashable, Sendable {
    /// Below this, water temperature is the dominant cause of under-extraction and
    /// should be fixed before anyone touches the grinder.
    public var coolWaterCelsius: Double
    /// How far past the method's expected maximum counts as a slow drawdown.
    public var drawdownOverrunSeconds: Int
    /// Ratio move for one strength adjustment, in 1:N.
    public var ratioStep: Double

    public init(
        coolWaterCelsius: Double = 88,
        drawdownOverrunSeconds: Int = 15,
        ratioStep: Double = 1
    ) {
        self.coolWaterCelsius = coolWaterCelsius
        self.drawdownOverrunSeconds = drawdownOverrunSeconds
        self.ratioStep = ratioStep
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
    public var grinder: Grinder?
    public var grinderSetting: Double?

    public init(
        taste: TasteRecord,
        method: BrewMethod,
        params: BrewParameters,
        actualTotalSeconds: Int? = nil,
        beanFreshness: Freshness? = nil,
        beanRestDays: Int? = nil,
        grinder: Grinder? = nil,
        grinderSetting: Double? = nil
    ) {
        self.taste = taste
        self.method = method
        self.params = params
        self.actualTotalSeconds = actualTotalSeconds
        self.beanFreshness = beanFreshness
        self.beanRestDays = beanRestDays
        self.grinder = grinder
        self.grinderSetting = grinderSetting
    }
}

/// Maps a taste record to one hypothesis and exactly one change.
///
/// The model separates two things beginners constantly conflate:
///
/// - **Extraction** — how much was pulled out of the grounds. Too little tastes
///   sour and thin-finished; too much tastes bitter and drying. Moved by grind.
/// - **Strength** — how much coffee is dissolved in the water. Too little is
///   watery; too much is muddy. Moved by ratio.
///
/// Rules are evaluated in order and the first match wins. Three principles are
/// baked into that ordering:
///
/// 1. **Rule out the bean before blaming the brewer.** Rules 1, 2 and 10 exist so
///    the app never sends someone chasing grind settings on coffee that was never
///    going to be good. Trust is built by saying "this isn't your fault."
/// 2. **Fix the dominant cause first.** Water far below temperature swamps grind,
///    so it is checked before the generic under-extraction rule.
/// 3. **Extraction before strength.** Grind moves both axes; ratio moves mainly
///    strength. Chasing strength first means redoing it after the grind changes.
///
/// No confidence scores, no regression, no model. A transparent table a coffee
/// professional can read and correct is worth more right now than something
/// nobody can debug — and it can be reviewed before launch, which a model can't.
public struct DiagnosisEngine: Sendable {
    public let thresholds: DiagnosisThresholds

    public init(thresholds: DiagnosisThresholds = .default) {
        self.thresholds = thresholds
    }

    public func diagnose(_ input: DiagnosisInput) -> Diagnosis {
        let taste = input.taste
        let isUnder = taste.extraction <= -1
        let isOver = taste.extraction >= 1
        let extractionIsFine = taste.extraction == 0

        // 1 — The bag is still degassing. Results are erratic; diagnosing them
        //     teaches the user something untrue about their technique.
        if input.beanFreshness == .resting, !taste.isBalanced {
            let days = input.beanRestDays.map { "\($0)" } ?? "a few"
            return Diagnosis(
                ruleID: 1,
                verdict: "Too soon to tell — this coffee is still degassing.",
                adjustment: .none,
                explanation: "At \(days) days off roast this bag is still pushing out CO₂, which disrupts extraction and makes results jump around. Give it two or three more days and brew it exactly the same way so you have something to compare.",
                conceptID: "degassing"
            )
        }

        // 2 — The bag is past it. No brew variable recovers stale coffee.
        if input.beanFreshness == .stale,
           !Set(taste.descriptors).isDisjoint(with: Descriptor.stalingSignals) {
            return Diagnosis(
                ruleID: 2,
                verdict: "Nothing to fix here — this bag is past its best.",
                adjustment: .none,
                explanation: "Flat, papery notes on an older bag are staling, not a brewing mistake. No grind or ratio change brings that back. Note it and move to a fresher coffee.",
                conceptID: "staling"
            )
        }

        // 3 — Water far below temperature is the dominant cause and swamps grind.
        //     This must be checked *before* rule 4, or it can never fire.
        if isUnder, let temp = input.params[.waterTemp], temp < thresholds.coolWaterCelsius {
            let target = Int(thresholds.coolWaterCelsius) + 6
            return Diagnosis(
                ruleID: 3,
                verdict: "Under-extracted — but your water was the likely culprit, not your grind.",
                adjustment: Adjustment(
                    kind: .hotterWater,
                    headline: "Use hotter water",
                    detail: "\(Int(temp.rounded())) °C → \(target) °C",
                    paramKey: .waterTemp,
                    newValue: Double(target)
                ),
                explanation: "Cooler water dissolves the sweet, heavier compounds much more slowly than the bright acidic ones, so the cup lands sour. Fix the temperature before touching the grinder — it's the bigger lever here.",
                conceptID: "water-temperature"
            )
        }

        // 4 — Classic under-extraction.
        if isUnder {
            return Diagnosis(
                ruleID: 4,
                verdict: verdictForUnder(taste),
                adjustment: grindAdjustment(finer: true, input: input),
                explanation: "Coarser grounds give the water less surface to work on, so it pulls out the bright, acidic compounds and never gets to the sweet ones. Grinding finer gives it more to hold on to.",
                conceptID: "under-extraction"
            )
        }

        // 5 — Over-extraction with a slow drawdown: name the mechanism the user
        //     can actually observe, so the advice is verifiable next time.
        if isOver, let actual = input.actualTotalSeconds,
           actual > input.method.expectedTotalSeconds.upperBound + thresholds.drawdownOverrunSeconds {
            return Diagnosis(
                ruleID: 5,
                verdict: "Over-extracted — and your drawdown ran long.",
                adjustment: grindAdjustment(finer: false, input: input),
                explanation: "This brew took \(BrewMath.formatSeconds(actual)) against an expected \(BrewMath.formatSeconds(input.method.expectedTotalSeconds.upperBound)). The water sat on the grounds too long and kept pulling out the bitter, drying compounds. Grinding coarser speeds the drawdown and shortens contact time.",
                conceptID: "drawdown"
            )
        }

        // 6 — Classic over-extraction.
        if isOver {
            return Diagnosis(
                ruleID: 6,
                verdict: verdictForOver(taste),
                adjustment: grindAdjustment(finer: false, input: input),
                explanation: "Finer grounds give water more surface and more time, and past a point it starts pulling out the bitter, drying compounds behind the sweetness. Grinding coarser pulls it back.",
                conceptID: "over-extraction"
            )
        }

        // 7 — Extraction is right; the cup is simply dilute.
        if extractionIsFine, taste.strength <= -1 {
            return Diagnosis(
                ruleID: 7,
                verdict: "Nothing wrong with your extraction — the cup is just dilute.",
                adjustment: ratioAdjustment(stronger: true, input: input),
                explanation: "Watery without being sour means you pulled the right things out, just into too much water. Keep the same grind and use less water — this is a strength problem, not an extraction one.",
                conceptID: "brew-ratio"
            )
        }

        // 8 — Extraction is right; the cup is over-concentrated.
        if extractionIsFine, taste.strength >= 1 {
            return Diagnosis(
                ruleID: 8,
                verdict: "Nothing wrong with your extraction — the cup is just too concentrated.",
                adjustment: ratioAdjustment(stronger: false, input: input),
                explanation: "Heavy and muddy without being bitter means the extraction landed, there's simply too much of it per sip. Keep the same grind and add water.",
                conceptID: "brew-ratio"
            )
        }

        // 9 — It worked.
        if taste.isBalanced, taste.rating >= 4 {
            return Diagnosis(
                ruleID: 9,
                verdict: "Balanced, and you liked it. This is your recipe now.",
                adjustment: .none,
                explanation: "Nothing to change. Save these numbers and brew them again tomorrow — repeating a good cup on purpose is the whole skill.",
                conceptID: nil
            )
        }

        // 10 — Technically sound but not enjoyable: a bean or water problem,
        //      not a brewing one. Saying so protects the user from chasing a
        //      dial that was never the issue.
        if taste.isBalanced {
            return Diagnosis(
                ruleID: 10,
                verdict: "Your brewing is dialled in — this is the coffee, not the technique.",
                adjustment: .none,
                explanation: "Balanced on both axes but still not enjoyable usually means the bean or the water, not the brew. Try a different coffee before changing anything about how you're making it.",
                conceptID: "water-chemistry"
            )
        }

        // 11 — Not enough signal.
        return Diagnosis(
            ruleID: 11,
            verdict: "Not enough to go on yet.",
            adjustment: .none,
            explanation: "Brew this one the same way once more so there's something to compare it against.",
            conceptID: nil
        )
    }

    // MARK: - Adjustment builders

    private func grindAdjustment(finer: Bool, input: DiagnosisInput) -> Adjustment {
        let kind: Adjustment.Kind = finer ? .grindFiner : .grindCoarser
        let headline = finer ? "Grind finer" : "Grind coarser"
        let steps = finer ? -1 : 1

        guard let grinder = input.grinder, let current = input.grinderSetting else {
            // No grinder configured — never show a meaningless number.
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "One step \(finer ? "finer" : "coarser") than last time.",
                paramKey: nil,
                newValue: nil,
                newGrinderSetting: nil
            )
        }

        let next = grinder.adjustedSetting(from: current, steps: steps)

        // Already at the end of the dial: say so rather than repeating advice
        // the user physically cannot follow.
        guard abs(next - current) > 0.001 else {
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "You're already at the \(finer ? "finest" : "coarsest") setting on your \(grinder.displayName). Adjust your ratio instead, or try a different coffee.",
                paramKey: nil,
                newValue: nil,
                newGrinderSetting: nil
            )
        }

        let detail = "\(grinder.format(current)) → \(grinder.format(next)) on your \(grinder.displayName)"
        return Adjustment(
            kind: kind,
            headline: headline,
            detail: detail,
            paramKey: .grind,
            newValue: grinder.normalised(fromSetting: next),
            newGrinderSetting: next
        )
    }

    private func ratioAdjustment(stronger: Bool, input: DiagnosisInput) -> Adjustment {
        let currentRatio = input.params.value(.ratio, default: 16)
        let dose = input.params.value(.dose, default: 15)
        let delta = stronger ? -thresholds.ratioStep : thresholds.ratioStep

        var nextRatio = currentRatio + delta
        if let def = input.method.param(.ratio) {
            nextRatio = def.clamp(nextRatio)
        }

        let kind: Adjustment.Kind = stronger ? .lessWater : .moreWater
        let headline = stronger ? "Use less water" : "Use more water"

        guard abs(nextRatio - currentRatio) > 0.001 else {
            return Adjustment(
                kind: kind,
                headline: headline,
                detail: "You're at the edge of the sensible range for this method — try a different dose instead.",
                paramKey: nil,
                newValue: nil
            )
        }

        let currentWater = BrewMath.water(dose: dose, ratio: currentRatio)
        let nextWater = BrewMath.water(dose: dose, ratio: nextRatio)
        let detail = "\(BrewMath.formatRatio(currentRatio)) → \(BrewMath.formatRatio(nextRatio)) — "
            + "\(BrewMath.formatGrams(currentWater)) → \(BrewMath.formatGrams(nextWater)) for your \(BrewMath.formatGrams(dose)) dose"

        return Adjustment(
            kind: kind,
            headline: headline,
            detail: detail,
            paramKey: .ratio,
            newValue: nextRatio
        )
    }

    // MARK: - Verdict copy

    private func verdictForUnder(_ taste: TasteRecord) -> String {
        switch taste.strength {
        case ..<0: return "Under-extracted — sour, and a bit thin with it."
        case 1...: return "Under-extracted — sour, and concentrated with it."
        default: return "Under-extracted — it came out sour."
        }
    }

    private func verdictForOver(_ taste: TasteRecord) -> String {
        switch taste.strength {
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
