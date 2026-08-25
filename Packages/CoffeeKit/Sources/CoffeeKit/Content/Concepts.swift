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
            and pull them out of the grounds. Water with none of them makes flat, hollow coffee \
            no matter how good the beans are. Very hard water goes chalky and dull.

            If you brew with RO or purifier water, that's the pure end of this, and it's the one \
            case worth doing something about: **try roughly seventy percent RO to thirty percent \
            tap.** It costs nothing, and it's usually the difference between coffee that stays \
            thin whatever you do to the grinder and coffee that works.

            Otherwise this is the variable to look at when your brewing is dialled in and the cup \
            still isn't enjoyable — both axes balanced, nothing left to adjust, and it's still \
            disappointing.
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
        ),

        Concept(
            id: "milk",
            term: "Milk in coffee",
            shortDefinition: "Fat and protein change the texture, and hide the acidity your palate would otherwise read.",
            card: """
            Milk does two things to coffee. Fat coats the tongue and rounds everything off; \
            protein gives you the foam and the body. Together they bind to a lot of the same \
            compounds that read as brightness and bitterness when you drink coffee black.

            That's why a milk coffee is hard to judge on sour-versus-bitter — the milk has \
            flattened the very thing you'd be tasting for. What you *can* still tell is whether \
            it's harsh and burnt at one end or thin and washed-out at the other, which is what \
            we ask you instead.

            For texture, fat and protein content matter more than the brand. Full-cream and \
            toned milk steam and froth better than double-toned; fresh milk behaves differently \
            from UHT, which has already been heated hard once. If you have a choice — Amul, \
            Nandini, Country Delight, whatever's local — pick on fat content first and taste second.
            """,
            relatedConceptIDs: ["strength", "roast-level"]
        ),

        Concept(
            id: "immersion",
            term: "Immersion brewing",
            shortDefinition: "The coffee sits in the water the whole time, instead of water passing through it.",
            card: """
            A French press, an AeroPress and a cup of cold brew are all immersion: the grounds and \
            the water stay together until you separate them. A pour-over is the opposite — water \
            passes through and leaves.

            The practical difference is which lever matters most. In a pour-over, grind mostly \
            controls things, because it sets how fast the water gets through. In immersion the \
            water isn't going anywhere, so **time is the first lever** and grind is the second.

            That's also why immersion is more forgiving. Thirty seconds either side of four \
            minutes is a small change; the same thirty seconds on a V60 is most of the brew.
            """,
            relatedConceptIDs: ["extraction", "fines"]
        ),

        Concept(
            id: "fines",
            term: "Fines",
            shortDefinition: "The dust-sized particles in any grind — they over-extract fast and end up in the cup.",
            card: """
            No grinder produces one particle size. Alongside the grounds you wanted there's always \
            a fraction of near-powder, and it behaves differently: enormous surface area, so it \
            gives up everything it has almost immediately.

            In a paper filter most of it gets caught. In a French press it doesn't — a metal mesh \
            lets fines straight through, which is where the silt at the bottom of the cup comes \
            from, and some of the bitterness with it.

            Two things reduce it. Grind a little coarser, and don't force the plunger down — \
            pressing hard pushes fines through the mesh that would otherwise have settled. \
            Or don't plunge at all: let them sink for a few minutes and pour off the top.
            """,
            relatedConceptIDs: ["immersion", "grind-size", "burr-grinder"]
        ),

        Concept(
            id: "chicory",
            term: "Chicory",
            shortDefinition: "A roasted root blended into South Indian filter coffee — not an adulterant, a choice.",
            card: """
            Chicory root, roasted and ground, is blended with coffee in most South Indian filter \
            coffee, usually somewhere between 10 and 30 percent. It has no caffeine and it isn't \
            coffee, but it isn't padding either.

            What it does is textural. Chicory is more soluble than coffee and gives a thicker, \
            darker decoction with a distinctive bittersweet edge — which is exactly what stands up \
            to a lot of hot milk and sugar. A filter coffee made with 100 percent coffee often \
            tastes thin in comparison, which surprises people who assumed the chicory was the \
            compromise.

            More chicory means a stronger-looking, faster-dripping decoction that can go flat and \
            slightly woody if you push it. It's a dial, not a defect.
            """,
            relatedConceptIDs: ["milk", "extraction"]
        ),

        Concept(
            id: "pre-ground",
            term: "Pre-ground coffee",
            shortDefinition: "Perfectly workable — but it fixes one variable, so the advice has to come from the others.",
            card: """
            Pre-ground coffee stales faster than whole beans, because grinding multiplies the \
            surface exposed to air. That's the usual argument for a grinder, and it's true.

            The more immediate thing is that grind is the strongest lever you have over how a cup \
            tastes, and buying pre-ground fixes it. You still have water temperature, contact time, \
            ratio and dose, and those are enough to make good coffee — you're just working with \
            four dials instead of five.

            It also means **matching the method to the grind you've got** rather than the other way \
            round. Most pre-ground sold in India is fine, aimed at filter coffee and moka pots, and \
            it will over-extract in a French press and stall a V60. If your coffee is bitter in a \
            pour-over and you can't grind coarser, the honest fix is a different brewer, not a \
            different technique.
            """,
            relatedConceptIDs: ["grind-size", "burr-grinder", "staling"]
        ),

        Concept(
            id: "about-cold-brew",
            term: "Cold brew",
            shortDefinition: "Coarse grounds steeped in cold water for twelve hours or more.",
            card: """
            No heat at all. Coarse coffee, cold water, roughly 1:8 for a concentrate you'll dilute, \
            and twelve to eighteen hours in the fridge. Strain, and it keeps for about a week.

            Cold water pulls out much less of the acidity and bitterness than hot water does, so \
            the result is sweet, smooth and very low in acidity. Some people find it flat for the \
            same reason.

            It's the easiest thing on this list to make and the hardest for us to help you improve, \
            because you taste the result half a day after every decision. That's why we describe it \
            rather than coach it — advice you can only test once a day isn't much of a loop.
            """,
            relatedConceptIDs: ["immersion", "extraction"]
        ),

        Concept(
            id: "about-espresso",
            term: "Espresso",
            shortDefinition: "Around nine bars of pressure forcing water through a packed puck in under half a minute.",
            card: """
            Everything is compressed: about 18 grams in, 36 out, in roughly 28 seconds. The \
            variables are different from filter coffee — dose, yield, time, pressure, temperature, \
            and how evenly you packed the basket — and so are the failure modes.

            It's also the base of nearly every milk drink you've ordered in a café, which is why \
            it's the method most people want and the one with the highest cost of entry. A machine \
            and a grinder that can actually do it is a serious purchase.

            We describe it rather than coach it because espresso needs its own diagnosis model, not \
            a translation of the filter one. Doing that badly would be worse than not doing it.
            """,
            relatedConceptIDs: ["milk", "extraction"]
        ),

        Concept(
            id: "about-instant",
            term: "Instant coffee",
            shortDefinition: "Coffee that was already brewed, then dried. You're rehydrating it, not making it.",
            card: """
            Instant is brewed at a factory, then freeze-dried or spray-dried into granules. Adding \
            water rehydrates it. Nothing you do at the kettle is extraction, which is why none of \
            the advice in this app applies to it.

            It is genuinely good at one thing: consistency. It tastes the same every time, takes \
            thirty seconds, and needs no equipment.

            What you gain by moving on isn't complexity, it's range. The same beans through a \
            French press cost you four minutes and a press you can buy for a few hundred rupees, \
            and the difference is not subtle. If you're going to try one thing after instant, that's \
            the one — it's the cheapest, most forgiving step up available.
            """,
            relatedConceptIDs: ["immersion", "staling"]
        ),

        Concept(
            id: "about-chemex",
            term: "Chemex",
            shortDefinition: "A pour-over with a much thicker filter, and the cleanest cup you can make.",
            card: """
            The brewer is one piece of glass, and the filters are markedly thicker than a V60's. \
            That thickness catches more oils and more fines, which is the whole point: the result \
            is exceptionally clean and light-bodied, with the flavours very clearly separated.

            The trade-off is speed and margin. Thicker paper drains more slowly, so a grind that \
            works on a V60 will often stall a Chemex, and the brews are long. It rewards a good \
            grinder more than most methods do.

            Technique-wise it's a V60 with more patience, which is why it's a natural second \
            pour-over rather than a first one.
            """,
            relatedConceptIDs: ["drawdown", "fines", "grind-size"]
        ),

        Concept(
            id: "about-siphon",
            term: "Siphon",
            shortDefinition: "Vapour pressure pushes water up into the grounds; taking the heat away pulls it back down.",
            card: """
            Two glass chambers and a heat source. Water in the lower bulb boils, vapour pressure \
            forces it up into the upper chamber where the coffee is, it steeps as a full immersion, \
            and when you take the heat away the vacuum pulls the brew back down through a filter.

            It's immersion and filtration in one, at a very stable high temperature, which gives a \
            cup that's clean and aromatic but with more body than paper pour-over.

            It is also glassware over an open flame on a weekday morning. Spectacular to watch, \
            genuinely good coffee, and almost nobody does it twice a day.
            """,
            relatedConceptIDs: ["immersion", "water-temperature"]
        ),

        Concept(
            id: "about-cezve",
            term: "Cezve / Turkish coffee",
            shortDefinition: "Powder-fine coffee simmered in a small pot and served without filtering.",
            card: """
            A long-handled pot, coffee ground finer than espresso — closer to flour — cold water, \
            and sugar added at the start if you want it. Bring it up slowly, let the foam rise, \
            take it off before it boils over, and repeat once or twice.

            Nothing is filtered out. The grounds settle in the cup and you stop drinking before you \
            reach them, which is why the grind has to be so fine and why the cup is thick and \
            intense. Cardamom is common; so is a lot of regional variation.

            One of the oldest ways of making coffee still in everyday use, and one of the very few \
            where the fine pre-ground coffee sold in most Indian shops is close to right.
            """,
            relatedConceptIDs: ["pre-ground", "grind-size"]
        )
    ]

    public static func concept(id: String) -> Concept? {
        all.first { $0.id == id }
    }

    public static var alphabetical: [Concept] {
        all.sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }
}
