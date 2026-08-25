import Foundation

/// Recipes for every method the app can actually time.
///
/// Reference-tier methods have none, deliberately: a recipe implies we can coach
/// you through it, and for those we can only describe.
extension BuiltInContent {

    // MARK: - V60

    public static let everydayV60 = Recipe(
        id: "v60-everyday",
        methodID: "v60",
        name: "Everyday V60",
        blurb: "Three pours, a clean cup, and enough structure to tell you something when it goes wrong.",
        parameters: BrewParameters([.dose: 15, .ratio: 16, .waterTemp: 94, .grind: 50]),
        steps: [
            RecipeStep(id: "bloom", kind: .bloom, startSeconds: 0, durationSeconds: 45,
                       cumulativeWaterFraction: 0.20,
                       instruction: "Pour to the bloom target, then swirl gently until every ground is wet.",
                       conceptID: "bloom"),
            RecipeStep(id: "pour-2", kind: .pour, startSeconds: 45, durationSeconds: 30,
                       cumulativeWaterFraction: 0.60,
                       instruction: "Pour in slow circles, keeping the bed level.",
                       conceptID: "agitation"),
            RecipeStep(id: "pour-3", kind: .pour, startSeconds: 75, durationSeconds: 30,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Final pour. Aim at the centre and work outward."),
            RecipeStep(id: "swirl", kind: .swirl, startSeconds: 105, durationSeconds: 8,
                       instruction: "One gentle swirl to settle the bed flat.",
                       conceptID: "channeling"),
            RecipeStep(id: "drawdown", kind: .drawdown, startSeconds: 113, durationSeconds: 67,
                       instruction: "Let it draw down. Don't touch it.",
                       conceptID: "drawdown")
        ],
        conceptIDs: ["bloom", "brew-ratio", "drawdown"]
    )

    public static let forgivingV60 = Recipe(
        id: "v60-forgiving",
        methodID: "v60",
        name: "Forgiving V60",
        blurb: "Two pours, coarser grind, wider margin for error. Use this while your pour is still finding itself.",
        parameters: BrewParameters([.dose: 15, .ratio: 16, .waterTemp: 93, .grind: 58]),
        steps: [
            RecipeStep(id: "bloom", kind: .bloom, startSeconds: 0, durationSeconds: 45,
                       cumulativeWaterFraction: 0.20,
                       instruction: "Pour to the bloom target and swirl until everything is wet.",
                       conceptID: "bloom"),
            RecipeStep(id: "pour-2", kind: .pour, startSeconds: 45, durationSeconds: 45,
                       cumulativeWaterFraction: 1.00,
                       instruction: "One steady pour all the way to the target. Slow and even beats fast and neat.",
                       conceptID: "agitation"),
            RecipeStep(id: "drawdown", kind: .drawdown, startSeconds: 90, durationSeconds: 105,
                       instruction: "Let it draw down completely.",
                       conceptID: "drawdown")
        ],
        conceptIDs: ["bloom", "grind-size"]
    )

    public static let clarityV60 = Recipe(
        id: "v60-clarity",
        methodID: "v60",
        name: "High Clarity V60",
        blurb: "Four pulse pours and a finer grind. More work, more separation between the flavours.",
        parameters: BrewParameters([.dose: 15, .ratio: 16.7, .waterTemp: 96, .grind: 44]),
        steps: [
            RecipeStep(id: "bloom", kind: .bloom, startSeconds: 0, durationSeconds: 45,
                       cumulativeWaterFraction: 0.18,
                       instruction: "Bloom and swirl. Watch how much it puffs — that's the CO₂ leaving.",
                       conceptID: "degassing"),
            RecipeStep(id: "pour-2", kind: .pour, startSeconds: 45, durationSeconds: 20,
                       cumulativeWaterFraction: 0.45,
                       instruction: "First pulse. Centre pour, small circles."),
            RecipeStep(id: "wait-1", kind: .wait, startSeconds: 65, durationSeconds: 10,
                       instruction: "Let the level drop before the next pulse."),
            RecipeStep(id: "pour-3", kind: .pour, startSeconds: 75, durationSeconds: 15,
                       cumulativeWaterFraction: 0.70, instruction: "Second pulse."),
            RecipeStep(id: "wait-2", kind: .wait, startSeconds: 90, durationSeconds: 10,
                       instruction: "Wait for the drop again."),
            RecipeStep(id: "pour-4", kind: .pour, startSeconds: 100, durationSeconds: 15,
                       cumulativeWaterFraction: 1.00, instruction: "Final pulse to the target."),
            RecipeStep(id: "drawdown", kind: .drawdown, startSeconds: 115, durationSeconds: 95,
                       instruction: "Let it run out. Expect a flat, even bed at the end.",
                       conceptID: "channeling")
        ],
        conceptIDs: ["agitation", "extraction", "grind-size"]
    )

    // MARK: - French press

    public static let everydayFrenchPress = Recipe(
        id: "fp-everyday",
        methodID: "frenchpress",
        name: "Everyday French Press",
        blurb: "All the water at once, four minutes, plunge slowly. The least you can do and still make good coffee.",
        parameters: BrewParameters([.dose: 30, .ratio: 16, .waterTemp: 95, .grind: 80, .steepTime: 240]),
        steps: [
            RecipeStep(id: "pour", kind: .pour, startSeconds: 0, durationSeconds: 30,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Pour all the water in at once, then give it one stir to wet every ground.",
                       conceptID: "immersion"),
            RecipeStep(id: "steep", kind: .wait, startSeconds: 30, durationSeconds: 210,
                       instruction: "Lid on, plunger up. Leave it alone."),
            RecipeStep(id: "crust", kind: .swirl, startSeconds: 240, durationSeconds: 20,
                       instruction: "Break the crust with a spoon and stir gently.",
                       conceptID: "immersion"),
            RecipeStep(id: "skim", kind: .swirl, startSeconds: 260, durationSeconds: 15,
                       instruction: "Skim off the foam and floating grounds."),
            RecipeStep(id: "plunge", kind: .press, startSeconds: 275, durationSeconds: 15,
                       instruction: "Plunge slowly, just to the surface. Pressing hard pushes fines through.",
                       conceptID: "fines")
        ],
        conceptIDs: ["immersion", "fines", "brew-ratio"]
    )

    public static let cleanFrenchPress = Recipe(
        id: "fp-clean",
        methodID: "frenchpress",
        name: "Clean French Press",
        blurb: "Never plunge. Let the fines sink for a few minutes and pour off the top — a much cleaner cup for a bit more patience.",
        parameters: BrewParameters([.dose: 30, .ratio: 16.5, .waterTemp: 95, .grind: 84, .steepTime: 240]),
        steps: [
            RecipeStep(id: "pour", kind: .pour, startSeconds: 0, durationSeconds: 30,
                       cumulativeWaterFraction: 1.00,
                       instruction: "All the water at once. Don't stir yet.",
                       conceptID: "immersion"),
            RecipeStep(id: "steep", kind: .wait, startSeconds: 30, durationSeconds: 210,
                       instruction: "Leave it completely alone for four minutes."),
            RecipeStep(id: "crust", kind: .swirl, startSeconds: 240, durationSeconds: 20,
                       instruction: "Break the crust. Most of the grounds will sink as you do."),
            RecipeStep(id: "skim", kind: .swirl, startSeconds: 260, durationSeconds: 20,
                       instruction: "Skim the foam and anything still floating."),
            RecipeStep(id: "settle", kind: .wait, startSeconds: 280, durationSeconds: 200,
                       instruction: "Wait. The fines are sinking — this is what makes the cup clean.",
                       conceptID: "fines"),
            RecipeStep(id: "pour-off", kind: .drawdown, startSeconds: 480, durationSeconds: 20,
                       instruction: "Pour off the top slowly, without pressing the plunger down.")
        ],
        conceptIDs: ["fines", "immersion"]
    )

    // MARK: - Tier 2

    public static let everydayAeropress = Recipe(
        id: "ap-everyday",
        methodID: "aeropress",
        name: "Everyday AeroPress",
        blurb: "Upright, short steep, slow press. Very hard to get wrong.",
        parameters: BrewParameters([.dose: 15, .ratio: 14, .waterTemp: 85, .grind: 40, .steepTime: 90]),
        steps: [
            RecipeStep(id: "pour", kind: .pour, startSeconds: 0, durationSeconds: 15,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Pour all the water in. Cooler than you'd think — 85 °C."),
            RecipeStep(id: "stir", kind: .swirl, startSeconds: 15, durationSeconds: 10,
                       instruction: "Stir three times, then put the plunger on to stop it dripping.",
                       conceptID: "agitation"),
            RecipeStep(id: "steep", kind: .wait, startSeconds: 25, durationSeconds: 65,
                       instruction: "Steep.", conceptID: "immersion"),
            RecipeStep(id: "press", kind: .press, startSeconds: 90, durationSeconds: 30,
                       instruction: "Press down slowly — about 30 seconds. Stop when you hear the hiss.")
        ],
        conceptIDs: ["immersion", "brew-ratio"]
    )

    public static let everydayMoka = Recipe(
        id: "moka-everyday",
        methodID: "moka",
        name: "Everyday Moka",
        blurb: "Pre-boiled water and a medium flame. The two things that stop a moka pot tasting burnt.",
        parameters: BrewParameters([.dose: 18, .ratio: 8, .waterTemp: 95, .grind: 22]),
        steps: [
            RecipeStep(id: "fill", kind: .pour, startSeconds: 0, durationSeconds: 30,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Fill the base with already-boiled water, to just under the valve. Level the grounds — don't tamp."),
            RecipeStep(id: "heat", kind: .wait, startSeconds: 30, durationSeconds: 150,
                       instruction: "Medium flame, lid open. Starting with hot water is what keeps the grounds from scorching.",
                       conceptID: "roast-level"),
            RecipeStep(id: "flow", kind: .drawdown, startSeconds: 180, durationSeconds: 60,
                       instruction: "It'll start running honey-coloured and steady. That's the part you want."),
            RecipeStep(id: "pull", kind: .press, startSeconds: 240, durationSeconds: 30,
                       instruction: "The moment it turns pale and starts spluttering, take it off and run the base under cold water.")
        ],
        conceptIDs: ["milk", "roast-level"]
    )

    public static let everydayFilterCoffee = Recipe(
        id: "sif-everyday",
        methodID: "southindianfilter",
        name: "Filter Coffee Decoction",
        blurb: "A fine grind, a light press, and a slow drip. Then milk, hot, and the pour between tumbler and dabara.",
        parameters: BrewParameters([.dose: 25, .ratio: 6, .waterTemp: 95, .grind: 12]),
        steps: [
            RecipeStep(id: "load", kind: .press, startSeconds: 0, durationSeconds: 30,
                       instruction: "Coffee into the upper chamber. Press the disc down gently — firm enough to hold, not packed."),
            RecipeStep(id: "pour", kind: .pour, startSeconds: 30, durationSeconds: 30,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Pour the water in slowly, then put the lid on."),
            RecipeStep(id: "drip", kind: .drawdown, startSeconds: 60, durationSeconds: 840,
                       instruction: "Now leave it. A good decoction takes fifteen minutes or so — rushing it is the usual mistake.",
                       conceptID: "chicory"),
            RecipeStep(id: "milk", kind: .swirl, startSeconds: 900, durationSeconds: 60,
                       instruction: "Roughly one part decoction to three parts hot milk. Sugar to taste, then pour it back and forth until it froths.",
                       conceptID: "milk")
        ],
        conceptIDs: ["milk", "chicory"]
    )

    public static let everydayKalita = Recipe(
        id: "kalita-everyday",
        methodID: "kalita",
        name: "Everyday Kalita",
        blurb: "Four even pours into a flat bed. The shape does more of the work than a cone does.",
        parameters: BrewParameters([.dose: 20, .ratio: 16, .waterTemp: 93, .grind: 48]),
        steps: [
            RecipeStep(id: "bloom", kind: .bloom, startSeconds: 0, durationSeconds: 45,
                       cumulativeWaterFraction: 0.20,
                       instruction: "Bloom, and swirl the whole brewer rather than stirring.",
                       conceptID: "bloom"),
            RecipeStep(id: "pour-2", kind: .pour, startSeconds: 45, durationSeconds: 25,
                       cumulativeWaterFraction: 0.50,
                       instruction: "Small circles in the middle. Keep the bed flat."),
            RecipeStep(id: "pour-3", kind: .pour, startSeconds: 80, durationSeconds: 25,
                       cumulativeWaterFraction: 0.75, instruction: "Again, same place."),
            RecipeStep(id: "pour-4", kind: .pour, startSeconds: 115, durationSeconds: 25,
                       cumulativeWaterFraction: 1.00, instruction: "Last pour to the target."),
            RecipeStep(id: "drawdown", kind: .drawdown, startSeconds: 140, durationSeconds: 60,
                       instruction: "Let it finish. A flat bed at the end means an even extraction.",
                       conceptID: "drawdown")
        ],
        conceptIDs: ["bloom", "drawdown"]
    )

    // MARK: - Registry

    public static let recipes: [Recipe] = [
        everydayV60, forgivingV60, clarityV60,
        everydayFrenchPress, cleanFrenchPress,
        everydayAeropress, everydayMoka, everydayFilterCoffee, everydayKalita
    ]

    public static func recipe(id: String) -> Recipe? {
        recipes.first { $0.id == id }
    }

    public static func recipes(forMethod methodID: String) -> [Recipe] {
        recipes.filter { $0.methodID == methodID }
    }

    /// What a brand-new user gets handed if they haven't chosen anything. Forgiving
    /// beats impressive: the first brew must not fail.
    public static let starterRecipe = forgivingV60

    /// The gentlest recipe available for a method — what a first-time attempt on an
    /// unfamiliar brewer should offer, rather than the highest-clarity one.
    public static func gentlestRecipe(forMethod methodID: String) -> Recipe? {
        let candidates = recipes(forMethod: methodID)
        return candidates.first { $0.id.contains("forgiving") || $0.id.contains("everyday") }
            ?? candidates.first
    }
}
