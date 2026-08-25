import Foundation

/// Tier 2 output: what usually goes wrong with a *brewer*, never a verdict on
/// this cup.
///
/// The copy names the limit out loud in every headline. That is deliberate and it
/// is the whole reason tier 2 is safe to ship: a confident-sounding paragraph that
/// turns out to be generic costs more trust than admitting we don't diagnose this
/// one yet. Users forgive a stated limit; they don't forgive finding one out.
extension MethodNotes {

    public static func forMethod(_ method: BrewMethod) -> MethodNotes {
        byMethodID[method.id] ?? generic(for: method)
    }

    private static func generic(for method: BrewMethod) -> MethodNotes {
        MethodNotes(
            methodID: method.id,
            headline: "We don't diagnose \(method.name.lowercased()) yet",
            notes: [
                Note(
                    title: "Change one thing at a time",
                    body: "Whatever you adjust next, adjust only it. Two changes in one brew and you learn nothing from the result — which is the mistake that keeps people stuck for years.",
                    conceptID: "extraction"
                )
            ]
        )
    }

    private static let byMethodID: [String: MethodNotes] = [

        BuiltInContent.aeropress.id: MethodNotes(
            methodID: BuiltInContent.aeropress.id,
            headline: "We don't diagnose AeroPress yet — here's what usually goes wrong",
            notes: [
                Note(
                    title: "Water hotter than it needs to be",
                    body: "An AeroPress is a short, concentrated immersion and it doesn't need boiling water. Around 80–85 °C is plenty for most coffee; hotter than that is the most common reason an AeroPress tastes harsh.",
                    conceptID: "water-temperature"
                ),
                Note(
                    title: "Pressing too hard",
                    body: "The press is meant to take about thirty seconds. Forcing it fast pushes fines through the paper and adds bitterness that had nothing to do with your recipe. Stop when you hear the hiss.",
                    conceptID: "fines"
                ),
                Note(
                    title: "It's more forgiving than you think",
                    body: "Steep time between one and three minutes all makes decent coffee. If something's wrong, look at temperature and grind before you start reworking the timings.",
                    conceptID: "immersion"
                )
            ]
        ),

        BuiltInContent.moka.id: MethodNotes(
            methodID: BuiltInContent.moka.id,
            headline: "We don't diagnose moka pots yet — but three things cause most bad ones",
            notes: [
                Note(
                    title: "Starting with cold water",
                    body: "Cold water in the base means the pot sits on the flame far longer, and the grounds cook while they wait. Fill it with already-boiled water and the whole brew gets shorter and sweeter. This single change fixes most burnt-tasting moka.",
                    conceptID: "water-temperature"
                ),
                Note(
                    title: "Too much heat",
                    body: "A high flame drives the water through fast and violently. Medium heat, lid open so you can watch it, and take it off the moment the flow turns pale and starts spluttering — that last part is bitter and you don't want it in the cup.",
                    conceptID: "extraction"
                ),
                Note(
                    title: "Tamping the basket",
                    body: "A moka pot isn't an espresso machine. Fill the basket and level it off — pressing the grounds down raises the pressure the pot has to fight and pushes it toward the burnt end.",
                    conceptID: "grind-size"
                )
            ]
        ),

        BuiltInContent.southIndianFilter.id: MethodNotes(
            methodID: BuiltInContent.southIndianFilter.id,
            headline: "We don't diagnose filter coffee yet — and if you already make it well, trust that",
            notes: [
                Note(
                    title: "Pressing the disc too hard",
                    body: "The upper chamber wants the coffee held, not packed. Press it down firmly enough that water can't channel around the edge, and no further — a tightly packed bed either stalls completely or drips so slowly the decoction goes bitter waiting.",
                    conceptID: "channeling"
                ),
                Note(
                    title: "Rushing the drip",
                    body: "A good decoction takes fifteen minutes or more. Lifting the lid to check, or shaking it along, are the two things most likely to leave you with something thin.",
                    conceptID: "extraction"
                ),
                Note(
                    title: "The chicory is a dial",
                    body: "More chicory gives a thicker, darker, faster-dripping decoction that stands up to more milk. Less lets the coffee itself through. Neither is the correct answer — it's a preference, and it's worth knowing you can move it.",
                    conceptID: "chicory"
                )
            ]
        ),

        BuiltInContent.kalita.id: MethodNotes(
            methodID: BuiltInContent.kalita.id,
            headline: "We don't diagnose Kalita yet — here's what usually goes wrong",
            notes: [
                Note(
                    title: "Pouring like it's a cone",
                    body: "A flat bed wants small circles near the middle. Wide, aggressive pours push grounds up the sides where the water then runs past them instead of through them.",
                    conceptID: "channeling"
                ),
                Note(
                    title: "Grinding for a V60",
                    body: "The three small holes restrict flow more than a cone does, so the same grind runs slower here. If your drawdown is dragging, go a step coarser than your V60 setting rather than changing the pour.",
                    conceptID: "drawdown"
                )
            ]
        )
    ]
}
