import Foundation

/// The concept library.
///
/// Deliberately small. A four-hundred-term glossary is a worse product than
/// sixteen entries someone actually reads. Every concept referenced by a
/// diagnosis rule or a recipe step must exist here — `ContentIntegrityTests`
/// enforces that, so a dangling reference fails the build rather than shipping
/// as a dead link in the one place a user asked for help.
public enum Concepts {

    public static let all: [Concept] = [

        Concept(
            id: "extraction",
            term: "Extraction",
            shortDefinition: "How much of the coffee you actually dissolved out of the grounds.",
            card: """
            Roasted coffee is mostly stuff that won't dissolve. Brewing is the act of \
            pulling out the fraction that will — around 18 to 22 percent of the bean's \
            weight, for most filter coffee.

            The order matters. Acids and fruity, sharp compounds come out first. \
            Sugars and the round, sweet notes follow. The bitter, drying compounds come \
            out last. That sequence is why a cup can be sour (you stopped too early) or \
            bitter (you went too far) rather than simply strong or weak.

            Almost everything you can change about a brew is really a way of changing \
            how far along that sequence you get.
            """,
            relatedConceptIDs: ["under-extraction", "over-extraction", "strength"]
        ),

        Concept(
            id: "strength",
            term: "Strength",
            shortDefinition: "How much dissolved coffee is in the water — separate from how well it was extracted.",
            card: """
            Strength and extraction are different things, and confusing them is the most \
            common reason people get stuck.

            Extraction is *how much you pulled out of the grounds*. Strength is *how much \
            of it ended up per sip*. You can have a strong, under-extracted cup — sour and \
            intense at once. You can have a weak, over-extracted one — bitter and watery.

            Strength is controlled by your ratio: the same extraction spread across more \
            water is a weaker cup. That's why the fix for "too watery, but not sour" is \
            less water, not a finer grind.
            """,
            relatedConceptIDs: ["brew-ratio", "extraction"]
        ),

        Concept(
            id: "under-extraction",
            term: "Under-extraction",
            shortDefinition: "You stopped before the sweetness arrived, so the sharp notes are all that's left.",
            card: """
            An under-extracted cup tastes sour or sharp, often a little salty, and the \
            finish disappears almost immediately. It can still be strong — under-extraction \
            is not the same as weak.

            It happens when water doesn't get enough access to the grounds: too coarse a \
            grind, water that's too cool, contact time that's too short, or channels in the \
            bed that let water run past the coffee instead of through it.

            The first lever is almost always grind. Finer grounds give the water more \
            surface to work on, and more of the sweetness comes with it.
            """,
            relatedConceptIDs: ["extraction", "grind-size", "channeling"]
        ),

        Concept(
            id: "over-extraction",
            term: "Over-extraction",
            shortDefinition: "You went past the sweetness into the bitter, drying compounds behind it.",
            card: """
            An over-extracted cup tastes bitter, harsh, or drying — that astringent feeling \
            on the sides of your tongue, like over-steeped tea. The flavours read as hollow \
            or ashy rather than sharp.

            It happens when water gets too much access: too fine a grind, water that's too \
            hot, too much agitation, or a drawdown that ran long.

            Grinding coarser is usually the first move. It speeds the drawdown and shortens \
            contact time in one change.
            """,
            relatedConceptIDs: ["extraction", "grind-size", "drawdown"]
        ),

        Concept(
            id: "brew-ratio",
            term: "Brew ratio",
            shortDefinition: "Grams of coffee to grams of water — the dial that controls strength.",
            card: """
            Written as 1:16 — one gram of coffee for every sixteen grams of water. Fifteen \
            grams of coffee at 1:16 is two hundred and forty grams of water.

            Ratio is your strength control. A tighter ratio (1:15) puts the same extraction \
            into less water and gives you a more concentrated cup. A wider one (1:17) spreads \
            it thinner.

            Change ratio when the cup is watery or heavy *without* being sour or bitter. If \
            it's sour or bitter, fix the grind first — grind moves both extraction and \
            strength, so adjusting ratio first means doing it twice.
            """,
            relatedConceptIDs: ["strength", "extraction"]
        ),

        Concept(
            id: "grind-size",
            term: "Grind size",
            shortDefinition: "The single most powerful variable you control, and the first one to change.",
            card: """
            Grinding finer creates more surface area and slows the water down, so the brew \
            extracts more. Grinding coarser does the opposite.

            Because it moves extraction *and* flow rate at once, grind is the strongest \
            lever on the board — which is exactly why you should change it alone. Move grind \
            and ratio in the same brew and you learn nothing from the result.

            One step at a time, in the same direction, until the sourness or the bitterness \
            goes. Then stop.
            """,
            relatedConceptIDs: ["burr-grinder", "under-extraction", "over-extraction"]
        ),

        Concept(
            id: "burr-grinder",
            term: "Burr grinder",
            shortDefinition: "A grinder that crushes beans to a consistent size, rather than smashing them to random ones.",
            card: """
            Blade grinders chop. You get boulders and dust in the same batch, and they \
            extract at completely different rates — the dust over-extracts while the boulders \
            are still sour. The cup tastes bitter and thin at the same time, and no amount \
            of technique fixes it.

            Burrs crush beans between two shaped surfaces at a set gap, so the particles come \
            out close to the same size and extract together.

            A burr grinder is the one piece of equipment that changes the ceiling of what \
            you can make. It matters more than the brewer.
            """,
            relatedConceptIDs: ["grind-size"]
        ),

        Concept(
            id: "bloom",
            term: "Bloom",
            shortDefinition: "The first small pour, which lets trapped CO₂ escape before the real brew starts.",
            card: """
            Fresh coffee is full of carbon dioxide from roasting. Hit it with hot water and \
            the gas rushes out, foaming the bed up and physically pushing water away from the \
            grounds it's supposed to be extracting.

            The bloom gets that out of the way. Pour roughly twice the weight of your dose, \
            make sure every ground is wet, and wait around forty-five seconds.

            The fresher the coffee, the more dramatically it puffs. A bag that barely blooms \
            at all is telling you it's old.
            """,
            relatedConceptIDs: ["degassing", "agitation"]
        ),

        Concept(
            id: "degassing",
            term: "Degassing",
            shortDefinition: "The few days after roasting when coffee is still venting CO₂ and brews unpredictably.",
            card: """
            Roasting fills beans with carbon dioxide, and it takes days to work its way out. \
            Until it does, that gas interferes with extraction — it pushes water away from the \
            grounds and makes results jump around from brew to brew.

            This is why very fresh coffee can taste worse than coffee a week older, and why \
            diagnosing a brew on a two-day-old bag teaches you something untrue about your \
            technique.

            Light roasts take longer than dark ones. When a bag is still resting, the right \
            move is to brew it the same way and wait, not to start changing things.
            """,
            relatedConceptIDs: ["bloom", "staling"]
        ),

        Concept(
            id: "staling",
            term: "Staling",
            shortDefinition: "The slow flattening of coffee weeks after roast — and it can't be brewed around.",
            card: """
            Once the CO₂ that protected them is gone, the aromatic compounds that make coffee \
            interesting start oxidising. The cup goes flat, papery, cardboard-like. Not bad \
            exactly — just absent.

            No grind or ratio change brings it back. This is the one failure mode where the \
            right advice is to stop adjusting and open a different bag.

            Whole beans stale far more slowly than ground. Grinding immediately before brewing \
            is the cheapest quality upgrade available.
            """,
            relatedConceptIDs: ["degassing"]
        ),

        Concept(
            id: "agitation",
            term: "Agitation",
            shortDefinition: "How much you stir things up — pouring, swirling, stirring — and it raises extraction.",
            card: """
            Every bit of movement brings fresh water into contact with grounds. More agitation \
            means more extraction, at the same grind and the same time.

            A high, fast pour agitates a lot. A gentle circular pour agitates less. A swirl at \
            the end evens out the bed.

            Agitation is the variable people change without realising it, which is why the \
            same recipe brewed by two people tastes different. Keeping your pour consistent is \
            what makes everything else measurable.
            """,
            relatedConceptIDs: ["channeling", "extraction"]
        ),

        Concept(
            id: "channeling",
            term: "Channeling",
            shortDefinition: "Water finding a fast path through the bed and skipping most of the coffee.",
            card: """
            If the grounds bed is uneven, water does what water does and takes the easy route. \
            The coffee along that channel gets over-extracted while everything else stays sour.

            The result tastes confusingly like both problems at once — bitter and thin, or sharp \
            with a drying finish — which is why it's worth ruling out before you start moving \
            the grinder.

            A gentle swirl after the last pour settles the bed flat. A crater or a high ring of \
            grounds up the sides after drawdown is the tell.
            """,
            relatedConceptIDs: ["agitation", "drawdown"]
        ),

        Concept(
            id: "drawdown",
            term: "Drawdown",
            shortDefinition: "The time it takes the last of the water to drain through — a readable signal about your grind.",
            card: """
            Drawdown is the clock the coffee keeps for you. For a standard V60 the whole brew \
            usually lands somewhere between two and a half and three and a half minutes.

            Much longer means the water is struggling through: too fine, too many fines, or too \
            much agitation. Much shorter means it's running straight past: too coarse, or a \
            channel somewhere.

            It's the one diagnostic you can read without tasting anything — which makes it a \
            useful cross-check on what your palate is telling you.
            """,
            relatedConceptIDs: ["grind-size", "channeling", "over-extraction"]
        ),

        Concept(
            id: "water-temperature",
            term: "Water temperature",
            shortDefinition: "Hotter water extracts faster; too cool and the cup lands sour no matter how you grind.",
            card: """
            Most filter brewing sits between ninety and ninety-six degrees Celsius. Light roasts \
            are denser and generally want the top of that range; darker roasts are already \
            soluble and can go lower.

            Temperature is a real lever, but it's a smaller one than grind — with an exception. \
            If your water is well below range, it becomes the dominant cause and grinding finer \
            just fights it. Fix the temperature first, then go back to the grinder.

            A kettle taken off the boil and left for thirty seconds is usually about right.
            """,
            relatedConceptIDs: ["extraction", "under-extraction"]
        ),

        Concept(
            id: "water-chemistry",
            term: "Water for coffee",
            shortDefinition: "Coffee is 98% water, and the minerals in yours decide how much flavour it can carry.",
            card: """
            Minerals in water — magnesium and calcium mostly — actively bind to flavour compounds \
            and pull them out of the grounds. Distilled water, with none of them, makes flat, \
            hollow coffee no matter how good the beans are. Very hard water goes chalky and dull.

            This is the variable to look at when your brewing is dialled in and the cup still \
            isn't enjoyable: both axes balanced, nothing left to adjust, and it's still \
            disappointing.

            A cheap filter jug is usually enough to find out whether it's your problem.
            """,
            relatedConceptIDs: ["extraction"]
        ),

        Concept(
            id: "roast-level",
            term: "Roast level",
            shortDefinition: "How far the beans were taken, which changes how soluble they are and how you should brew them.",
            card: """
            Lighter roasts keep more of the origin's own character — florals, fruit, acidity — but \
            they're denser and harder to extract. They want hotter water, a finer grind, and more \
            days of rest before they settle.

            Darker roasts have had more of that character replaced with roast flavour. They're \
            more soluble, so they extract faster and need cooler water and a coarser grind to \
            avoid going bitter.

            When you switch between them, expect to re-dial. It isn't your technique slipping.
            """,
            relatedConceptIDs: ["degassing", "water-temperature"]
        )
    ]

    public static func concept(id: String) -> Concept? {
        all.first { $0.id == id }
    }

    public static var alphabetical: [Concept] {
        all.sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }
}
