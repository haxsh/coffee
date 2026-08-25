import Foundation

/// The v1 content bundle, compiled into the app.
///
/// Shipping this in-binary rather than fetching it is why every feature works in
/// airplane mode: no spinner is ever acceptable mid-pour. Remote updates, when they
/// arrive, are additive and fail silently back to these values.
///
/// Twelve methods at three tiers. Breadth is affordable precisely because they are
/// not supported equally — a `.reference` method costs a paragraph, and says so.
public enum BuiltInContent {

    // MARK: - Tier 1 — full diagnosis

    public static let v60 = BrewMethod(
        id: "v60",
        name: "V60",
        blurb: "Cone pour-over. The most variable-sensitive brewer in common use — which is exactly why it's the one worth learning on.",
        symbolName: "triangle",
        supportTier: .full,
        profile: MethodProfile(
            effort: 4, time: 2, gearCost: 2, forgiveness: 4,
            tastesLike: "Clean and bright. Light body, and you taste where the coffee came from.",
            worksWithPreGround: false
        ),
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 8, maximum: 60, step: 0.5, defaultValue: 15),
            ParamDef(key: .ratio, unit: .ratio, minimum: 13, maximum: 20, step: 0.5, defaultValue: 16),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 80, maximum: 100, step: 1, defaultValue: 94),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 50)
        ],
        expectedTotalSeconds: 150...225,
        conceptIDs: ["extraction", "brew-ratio", "bloom", "agitation", "drawdown", "channeling"]
    )

    /// The second full rule table, and the deliberate test of whether the tier model
    /// generalises. It reasons differently from the V60: immersion is time-dominant,
    /// so steep time is the first lever and grind is the second — the reverse of
    /// pour-over. If the model only worked for methods shaped like V60, this is
    /// where it would have shown.
    public static let frenchPress = BrewMethod(
        id: "frenchpress",
        name: "French press",
        blurb: "Full immersion. Almost no technique, a heavy sweet cup, and the most forgiving brewer you can own.",
        symbolName: "square",
        supportTier: .full,
        profile: MethodProfile(
            effort: 1, time: 3, gearCost: 1, forgiveness: 1,
            tastesLike: "Heavy and round. Big body, low acidity, a little sediment at the bottom.",
            worksWithPreGround: true
        ),
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 10, maximum: 100, step: 1, defaultValue: 30),
            ParamDef(key: .ratio, unit: .ratio, minimum: 12, maximum: 18, step: 0.5, defaultValue: 16),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 80, maximum: 100, step: 1, defaultValue: 95),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 80),
            ParamDef(key: .steepTime, unit: .seconds, minimum: 120, maximum: 600, step: 30, defaultValue: 240)
        ],
        expectedTotalSeconds: 240...600,
        conceptIDs: ["immersion", "fines", "brew-ratio", "extraction"]
    )

    // MARK: - Tier 2 — guided, but no per-symptom diagnosis

    public static let aeropress = BrewMethod(
        id: "aeropress",
        name: "AeroPress",
        blurb: "Immersion plus a gentle push through a paper filter. Hard to ruin, endlessly tinkerable, and it packs in a bag.",
        symbolName: "cylinder",
        supportTier: .guided,
        profile: MethodProfile(
            effort: 2, time: 1, gearCost: 2, forgiveness: 1,
            tastesLike: "Clean like a pour-over but rounder. Concentrated, and very hard to make taste bad.",
            worksWithPreGround: true
        ),
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 10, maximum: 25, step: 0.5, defaultValue: 15),
            ParamDef(key: .ratio, unit: .ratio, minimum: 10, maximum: 18, step: 0.5, defaultValue: 14),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 70, maximum: 100, step: 1, defaultValue: 85),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 40),
            ParamDef(key: .steepTime, unit: .seconds, minimum: 30, maximum: 300, step: 15, defaultValue: 90)
        ],
        expectedTotalSeconds: 60...180,
        conceptIDs: ["immersion", "brew-ratio", "extraction"]
    )

    public static let moka = BrewMethod(
        id: "moka",
        name: "Moka pot",
        blurb: "Steam pressure through a fine bed. Strong, dark and unfussy — the stovetop pot half of India already has in a cupboard.",
        symbolName: "hexagon",
        supportTier: .guided,
        profile: MethodProfile(
            effort: 2, time: 3, gearCost: 1, forgiveness: 3,
            tastesLike: "Strong, dark and syrupy. Not espresso, but the closest a stovetop gets. Takes milk well.",
            worksWithPreGround: true
        ),
        takesMilk: true,
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 10, maximum: 40, step: 1, defaultValue: 18),
            ParamDef(key: .ratio, unit: .ratio, minimum: 6, maximum: 12, step: 0.5, defaultValue: 8),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 60, maximum: 100, step: 5, defaultValue: 95),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 22)
        ],
        expectedTotalSeconds: 180...420,
        conceptIDs: ["milk", "roast-level", "extraction"]
    )

    /// Culturally central to this market, and modelled by nobody else. Treated as a
    /// first-class method rather than a curiosity — the tone matters as much as the
    /// timings here, because for many users this is not a new thing to try, it is
    /// how coffee is already made at home.
    public static let southIndianFilter = BrewMethod(
        id: "southindianfilter",
        name: "South Indian filter",
        blurb: "A two-chamber steel filter, a very fine grind, and a slow drip into a strong decoction. Then hot milk, and a pour between tumbler and dabara.",
        symbolName: "cylinder.split.1x2",
        supportTier: .guided,
        profile: MethodProfile(
            effort: 2, time: 5, gearCost: 1, forgiveness: 2,
            tastesLike: "Deep, bittersweet and unmistakable. Built for milk and sugar, not for drinking black.",
            worksWithPreGround: true
        ),
        takesMilk: true,
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 10, maximum: 60, step: 1, defaultValue: 25),
            ParamDef(key: .ratio, unit: .ratio, minimum: 3, maximum: 10, step: 0.5, defaultValue: 6),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 80, maximum: 100, step: 1, defaultValue: 95),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 12)
        ],
        expectedTotalSeconds: 600...1500,
        conceptIDs: ["milk", "chicory", "extraction"]
    )

    public static let kalita = BrewMethod(
        id: "kalita",
        name: "Kalita Wave",
        blurb: "Flat-bottom pour-over. The same idea as a V60 with more of the timing taken out of your hands.",
        symbolName: "circle.bottomhalf.filled",
        supportTier: .guided,
        profile: MethodProfile(
            effort: 3, time: 2, gearCost: 3, forgiveness: 2,
            tastesLike: "Clean like a V60 but a little rounder and more even. Easier to repeat.",
            worksWithPreGround: false
        ),
        paramSchema: [
            ParamDef(key: .dose, unit: .grams, minimum: 10, maximum: 40, step: 0.5, defaultValue: 20),
            ParamDef(key: .ratio, unit: .ratio, minimum: 13, maximum: 18, step: 0.5, defaultValue: 16),
            ParamDef(key: .waterTemp, unit: .celsius, minimum: 80, maximum: 100, step: 1, defaultValue: 93),
            ParamDef(key: .grind, unit: .coarseness, minimum: 0, maximum: 100, step: 1, defaultValue: 48)
        ],
        expectedTotalSeconds: 150...240,
        conceptIDs: ["bloom", "drawdown", "brew-ratio"]
    )

    // MARK: - Tier 3 — reference only

    private static func reference(
        id: String,
        name: String,
        blurb: String,
        symbolName: String,
        profile: MethodProfile,
        takesMilk: Bool = false,
        conceptID: String
    ) -> BrewMethod {
        BrewMethod(
            id: id, name: name, blurb: blurb, symbolName: symbolName,
            supportTier: .reference, profile: profile, takesMilk: takesMilk,
            paramSchema: [],
            // Never used — a reference method has no brew to time. Kept non-empty
            // only because the type demands a range.
            expectedTotalSeconds: 0...0,
            conceptIDs: [conceptID]
        )
    }

    public static let referenceMethods: [BrewMethod] = [
        reference(
            id: "coldbrew", name: "Cold brew",
            blurb: "Coarse grounds, cold water, twelve hours of waiting. We can tell you about it, but a brew you taste tomorrow can't be coached one cup at a time.",
            symbolName: "snowflake",
            profile: MethodProfile(effort: 1, time: 5, gearCost: 1, forgiveness: 1,
                                   tastesLike: "Sweet, smooth and very low in acidity. Almost no bitterness.",
                                   worksWithPreGround: true),
            conceptID: "about-cold-brew"
        ),
        reference(
            id: "espresso", name: "Espresso",
            blurb: "Nine bars of pressure through a packed puck. A different set of variables and a different way of going wrong — it needs its own model, and it'll get one.",
            symbolName: "drop",
            profile: MethodProfile(effort: 5, time: 1, gearCost: 5, forgiveness: 5,
                                   tastesLike: "Intense and syrupy. The base of every milk drink you order out.",
                                   worksWithPreGround: false),
            takesMilk: true,
            conceptID: "about-espresso"
        ),
        reference(
            id: "instant", name: "Instant",
            blurb: "Already brewed, dried, and waiting for hot water. Where most people start — and there's an honest case for what changes when you move on.",
            symbolName: "bolt",
            profile: MethodProfile(effort: 1, time: 1, gearCost: 1, forgiveness: 1,
                                   tastesLike: "Consistent, flat, and roasty. The floor is high and the ceiling is low.",
                                   worksWithPreGround: true),
            takesMilk: true,
            conceptID: "about-instant"
        ),
        reference(
            id: "chemex", name: "Chemex",
            blurb: "A pour-over with a much thicker filter. Very clean, very slow, and it looks like laboratory glassware because it more or less is.",
            symbolName: "hourglass",
            profile: MethodProfile(effort: 4, time: 3, gearCost: 4, forgiveness: 3,
                                   tastesLike: "The cleanest cup on this list. Almost no body, all clarity.",
                                   worksWithPreGround: false),
            conceptID: "about-chemex"
        ),
        reference(
            id: "siphon", name: "Siphon",
            blurb: "Vapour pressure pushes water up, gravity pulls the brew back down. Genuinely spectacular, genuinely impractical on a weekday.",
            symbolName: "flame",
            profile: MethodProfile(effort: 5, time: 3, gearCost: 5, forgiveness: 4,
                                   tastesLike: "Clean and aromatic, with more body than a paper pour-over.",
                                   worksWithPreGround: false),
            conceptID: "about-siphon"
        ),
        reference(
            id: "cezve", name: "Cezve / Turkish",
            blurb: "Powder-fine coffee simmered in a small pot and poured grounds and all. Among the oldest ways of making coffee still in daily use.",
            symbolName: "triangle.bottomhalf.filled",
            profile: MethodProfile(effort: 3, time: 2, gearCost: 1, forgiveness: 3,
                                   tastesLike: "Thick, intense and a little gritty by design. Often spiced.",
                                   worksWithPreGround: true),
            conceptID: "about-cezve"
        )
    ]

    // MARK: - Registry

    public static let methods: [BrewMethod] =
        [v60, frenchPress, aeropress, moka, southIndianFilter, kalita] + referenceMethods

    public static func method(id: String) -> BrewMethod? {
        methods.first { $0.id == id }
    }

    public static var brewableMethods: [BrewMethod] { methods.filter(\.canBrew) }
    public static var diagnosableMethods: [BrewMethod] { methods.filter(\.canDiagnose) }
}
