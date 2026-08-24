import Foundation

public enum BrewMath {
    /// Water is always derived from the dose the user actually weighed — never
    /// stored as a primary. Change the dose and every target recomputes.
    public static func water(dose: Double, ratio: Double) -> Double {
        guard ratio > 0 else { return 0 }
        return dose * ratio
    }

    public static func dose(water: Double, ratio: Double) -> Double {
        guard ratio > 0 else { return 0 }
        return water / ratio
    }

    public static func ratio(dose: Double, water: Double) -> Double {
        guard dose > 0 else { return 0 }
        return water / dose
    }

    /// Cumulative water target at the end of each step, in grams.
    ///
    /// Steps that don't pour carry the previous total forward, so the number on
    /// screen always matches what the scale reads — the user never adds anything up.
    public static func cumulativeTargets(steps: [RecipeStep], totalWater: Double) -> [Double] {
        var running: Double = 0
        return steps.map { step in
            if let fraction = step.cumulativeWaterFraction {
                running = (totalWater * fraction).rounded()
            }
            return running
        }
    }

    /// Grams to add during a step. Shown as a secondary cue only — the
    /// cumulative target is always the primary number.
    public static func stepIncrements(steps: [RecipeStep], totalWater: Double) -> [Double] {
        let targets = cumulativeTargets(steps: steps, totalWater: totalWater)
        var previous: Double = 0
        return targets.map { target in
            let delta = max(0, target - previous)
            previous = target
            return delta
        }
    }

    public static func formatSeconds(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    public static func formatGrams(_ grams: Double) -> String {
        String(format: "%.0f g", grams.rounded())
    }

    public static func formatRatio(_ ratio: Double) -> String {
        let rounded = (ratio * 10).rounded() / 10
        if abs(rounded - rounded.rounded()) < 0.05 {
            return String(format: "1:%.0f", rounded)
        }
        return String(format: "1:%.1f", rounded)
    }
}
