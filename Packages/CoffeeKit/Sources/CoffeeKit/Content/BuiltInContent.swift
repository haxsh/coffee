import Foundation

/// The v1 content bundle, compiled into the app.
///
/// Shipping this in-binary rather than fetching it is why every feature works in
/// airplane mode: no spinner is ever acceptable mid-pour. Remote updates, when
/// they arrive, are additive and fail silently back to these values.
public enum BuiltInContent {

    // MARK: - Methods

    public static let v60 = BrewMethod(
        id: "v60",
        name: "V60",
        blurb: "Cone pour-over. The most variable-sensitive brewer in common use — which is exactly why it's the one worth learning on.",
        symbolName: "triangle",
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 8, maximum: 60, step: 0.5, defaultValue: 15),
            ParamDef(key: .ratio, unit: .ratio, minimum: 13, maximum: 20, step: 0.5, defaultValue: 16),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 80, maximum: 100, step: 1, defaultValue: 94),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 50)
        ],
        expectedTotalSeconds: 150...225,
        conceptIDs: ["extraction", "brew-ratio", "bloom", "agitation", "drawdown", "channeling"]
    )

    /// Locked in v1 — visible with a badge rather than hidden, so users learn the
    /// app has them. Hiding paid content means nobody ever discovers it.
    public static let lockedMethods: [BrewMethod] = [
        BrewMethod(id: "aeropress", name: "AeroPress", blurb: "Immersion and pressure. Forgiving, portable, and hard to ruin.",
                   symbolName: "cylinder", paramSchema: [], expectedTotalSeconds: 60...180, isLocked: true),
        BrewMethod(id: "frenchpress", name: "French Press", blurb: "Full immersion, full body, almost no technique required.",
                   symbolName: "square", paramSchema: [], expectedTotalSeconds: 240...480, isLocked: true),
        BrewMethod(id: "espresso", name: "Espresso", blurb: "Different variables, different rules. Coming as its own thing, properly done.",
                   symbolName: "drop", paramSchema: [], expectedTotalSeconds: 20...40, isLocked: true)
    ]

    public static let methods: [BrewMethod] = [v60] + lockedMethods

    public static func method(id: String) -> BrewMethod? {
        methods.first { $0.id == id }
    }

    // MARK: - Recipes

    public static let everydayV60 = Recipe(
        id: "v60-everyday",
        methodID: "v60",
        name: "Everyday V60",
        blurb: "Three pours, a clean cup, and enough structure to tell you something when it goes wrong. Start here.",
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
                       instruction: "Final pour. Aim at the centre and work outward.",
                       conceptID: nil),
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
        blurb: "Two pours, coarser grind, wider margin for error. The one to use while your pour is still finding itself.",
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
        blurb: "Four pulse pours and a finer grind. More work, more separation between the flavours — best on a light roast you already like.",
        parameters: BrewParameters([.dose: 15, .ratio: 16.7, .waterTemp: 96, .grind: 44]),
        steps: [
            RecipeStep(id: "bloom", kind: .bloom, startSeconds: 0, durationSeconds: 45,
                       cumulativeWaterFraction: 0.18,
                       instruction: "Bloom and swirl. Watch how much it puffs — that's the CO₂ leaving.",
                       conceptID: "degassing"),
            RecipeStep(id: "pour-2", kind: .pour, startSeconds: 45, durationSeconds: 20,
                       cumulativeWaterFraction: 0.45,
                       instruction: "First pulse. Centre pour, small circles.", conceptID: nil),
            RecipeStep(id: "wait-1", kind: .wait, startSeconds: 65, durationSeconds: 10,
                       instruction: "Let the level drop before the next pulse.", conceptID: nil),
            RecipeStep(id: "pour-3", kind: .pour, startSeconds: 75, durationSeconds: 15,
                       cumulativeWaterFraction: 0.70,
                       instruction: "Second pulse.", conceptID: nil),
            RecipeStep(id: "wait-2", kind: .wait, startSeconds: 90, durationSeconds: 10,
                       instruction: "Wait for the drop again.", conceptID: nil),
            RecipeStep(id: "pour-4", kind: .pour, startSeconds: 100, durationSeconds: 15,
                       cumulativeWaterFraction: 1.00,
                       instruction: "Final pulse to the target.", conceptID: nil),
            RecipeStep(id: "drawdown", kind: .drawdown, startSeconds: 115, durationSeconds: 95,
                       instruction: "Let it run out. Expect a flat, even bed at the end.",
                       conceptID: "channeling")
        ],
        conceptIDs: ["agitation", "extraction", "grind-size"]
    )

    public static let recipes: [Recipe] = [everydayV60, forgivingV60, clarityV60]

    public static func recipe(id: String) -> Recipe? {
        recipes.first { $0.id == id }
    }

    public static func recipes(forMethod methodID: String) -> [Recipe] {
        recipes.filter { $0.methodID == methodID }
    }

    /// What a brand-new user gets handed. Forgiving beats impressive: the first
    /// brew must not fail.
    public static let starterRecipe = forgivingV60
}
