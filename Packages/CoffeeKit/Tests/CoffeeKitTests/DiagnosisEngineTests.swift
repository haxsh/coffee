import XCTest
@testable import CoffeeKit

/// The diagnosis engine is the product. These tests are the reason it lives in a
/// plain Swift package rather than inside the app target — the whole rule table
/// is verifiable without a simulator, a UI, or a Mac.
final class DiagnosisEngineTests: XCTestCase {

    private let engine = DiagnosisEngine()

    private func input(
        extraction: Int,
        strength: Int,
        rating: Int = 3,
        descriptors: [Descriptor] = [],
        temp: Double = 94,
        totalSeconds: Int? = 180,
        freshness: Freshness? = .peak,
        restDays: Int? = 10,
        grinder: Grinder? = .baratzaEncore,
        setting: Double? = 18,
        ratio: Double = 16,
        dose: Double = 15
    ) -> DiagnosisInput {
        DiagnosisInput(
            taste: TasteRecord(rating: rating, extraction: extraction, strength: strength, descriptors: descriptors),
            method: BuiltInContent.v60,
            params: BrewParameters([.dose: dose, .ratio: ratio, .waterTemp: temp, .grind: 50]),
            actualTotalSeconds: totalSeconds,
            beanFreshness: freshness,
            beanRestDays: restDays,
            grinder: grinder,
            grinderSetting: setting
        )
    }

    // MARK: - The grid

    /// The nine cells of the extraction × strength grid, exactly as published in
    /// the spec. Because extraction is always fixed before strength, the sour
    /// column is uniformly "finer" and the bitter column uniformly "coarser" —
    /// only the balanced column varies by strength. If that stops being true,
    /// the grid in the design doc is lying to the reader.
    func testGridProducesOneAdjustmentPerCell() {
        let expected: [(extraction: Int, strength: Int, kind: Adjustment.Kind)] = [
            (-2,  2, .grindFiner),   (0,  2, .moreWater),  (2,  2, .grindCoarser),
            (-2,  0, .grindFiner),   (0,  0, .none),       (2,  0, .grindCoarser),
            (-2, -2, .grindFiner),   (0, -2, .lessWater),  (2, -2, .grindCoarser)
        ]

        for cell in expected {
            // Rating 4 on the balanced/balanced cell so it lands on "it worked"
            // rather than the bean-problem rule.
            let rating = (cell.extraction == 0 && cell.strength == 0) ? 4 : 2
            let result = engine.diagnose(input(extraction: cell.extraction, strength: cell.strength, rating: rating))
            XCTAssertEqual(
                result.adjustment.kind, cell.kind,
                "cell (extraction: \(cell.extraction), strength: \(cell.strength)) gave \(result.adjustment.kind) via rule \(result.ruleID)"
            )
        }
    }

    func testEveryDiagnosisSuggestsAtMostOneChange() {
        for extraction in -2...2 {
            for strength in -2...2 {
                for rating in 1...5 {
                    let result = engine.diagnose(input(extraction: extraction, strength: strength, rating: rating))
                    // The type makes more than one impossible; this asserts the
                    // engine always resolves rather than falling through.
                    XCTAssertFalse(result.verdict.isEmpty)
                    XCTAssertFalse(result.explanation.isEmpty)
                }
            }
        }
    }

    // MARK: - Rule ordering

    func testRestingBeanBeatsExtractionAdvice() {
        let result = engine.diagnose(input(extraction: -2, strength: -1, freshness: .resting, restDays: 2))
        XCTAssertEqual(result.ruleID, 1)
        XCTAssertFalse(result.adjustment.isActionable, "A degassing bag should never be sent to the grinder")
        XCTAssertEqual(result.conceptID, "degassing")
    }

    func testRestingBeanStillCongratulatesABalancedCup() {
        // Rule 1 only fires when something is actually off — a good cup on a
        // resting bag shouldn't be second-guessed.
        let result = engine.diagnose(input(extraction: 0, strength: 0, rating: 5, freshness: .resting, restDays: 2))
        XCTAssertEqual(result.ruleID, 9)
    }

    func testStaleBeanNeedsAStalingDescriptorToFire() {
        let withSignal = engine.diagnose(input(extraction: 0, strength: 0, rating: 2, descriptors: [.flat], freshness: .stale, restDays: 60))
        XCTAssertEqual(withSignal.ruleID, 2)
        XCTAssertEqual(withSignal.conceptID, "staling")

        let withoutSignal = engine.diagnose(input(extraction: 2, strength: 0, rating: 2, descriptors: [.drying], freshness: .stale, restDays: 60))
        XCTAssertEqual(withoutSignal.ruleID, 6, "A bitter cup on an old bag is still a brewing problem")
    }

    /// Regression: the temperature rule was originally ordered *after* the generic
    /// under-extraction rule, which made it unreachable — every `extraction <= -1`
    /// was caught by the grind rule first. It also gives the wrong advice: water
    /// well below range swamps grind, so it has to be fixed first.
    func testCoolWaterIsCheckedBeforeGrind() {
        let result = engine.diagnose(input(extraction: -2, strength: 0, temp: 82))
        XCTAssertEqual(result.ruleID, 3)
        XCTAssertEqual(result.adjustment.kind, .hotterWater)
        XCTAssertEqual(result.adjustment.paramKey, .waterTemp)
    }

    func testCoolWaterRuleDoesNotFireWhenExtractionIsFine() {
        let result = engine.diagnose(input(extraction: 0, strength: -2, temp: 82))
        XCTAssertEqual(result.ruleID, 7, "Cool water is only the answer when the cup is actually under-extracted")
        XCTAssertEqual(result.adjustment.kind, .lessWater)
    }

    func testSlowDrawdownIsNamedWhenItRanLong() {
        let slow = engine.diagnose(input(extraction: 2, strength: 0, totalSeconds: 300))
        XCTAssertEqual(slow.ruleID, 5)
        XCTAssertEqual(slow.conceptID, "drawdown")
        XCTAssertTrue(slow.explanation.contains("5:00"), "The verdict should quote the actual time back to the user")

        let normal = engine.diagnose(input(extraction: 2, strength: 0, totalSeconds: 180))
        XCTAssertEqual(normal.ruleID, 6)
    }

    func testBalancedButUnenjoyablePointsAtTheBeanNotTheBrewer() {
        let result = engine.diagnose(input(extraction: 0, strength: 0, rating: 2))
        XCTAssertEqual(result.ruleID, 10)
        XCTAssertFalse(result.adjustment.isActionable)
        XCTAssertEqual(result.conceptID, "water-chemistry")
    }

    // MARK: - Advice is spoken in the user's units

    func testGrindAdviceUsesTheUsersOwnDial() {
        let result = engine.diagnose(input(extraction: -2, strength: 0, grinder: .baratzaEncore, setting: 18))
        XCTAssertEqual(result.adjustment.kind, .grindFiner)
        XCTAssertEqual(result.adjustment.newGrinderSetting, 16, "Encore moves two clicks per adjustment step")
        XCTAssertTrue(result.adjustment.detail.contains("18 clicks"))
        XCTAssertTrue(result.adjustment.detail.contains("16 clicks"))
        XCTAssertTrue(result.adjustment.detail.contains("Baratza Encore"))
    }

    func testGrindAdviceFallsBackToWordsWithNoGrinder() {
        let result = engine.diagnose(input(extraction: -2, strength: 0, grinder: nil, setting: nil))
        XCTAssertEqual(result.adjustment.kind, .grindFiner)
        XCTAssertNil(result.adjustment.newGrinderSetting)
        XCTAssertFalse(result.adjustment.detail.contains("→"), "Never show a number we can't ground in the user's grinder")
    }

    func testGrindAdviceAtTheEndOfTheDialSaysSoInsteadOfRepeating() {
        // Already at 1 click on an Encore: finer is not physically available.
        let result = engine.diagnose(input(extraction: -2, strength: 0, grinder: .baratzaEncore, setting: 1))
        XCTAssertEqual(result.adjustment.kind, .grindFiner)
        XCTAssertNil(result.adjustment.newGrinderSetting)
        XCTAssertTrue(result.adjustment.detail.lowercased().contains("finest"))
    }

    func testRatioAdviceQuotesBothRatioAndGrams() {
        let result = engine.diagnose(input(extraction: 0, strength: -2, ratio: 16, dose: 15))
        XCTAssertEqual(result.adjustment.kind, .lessWater)
        XCTAssertEqual(result.adjustment.newValue, 15)
        XCTAssertTrue(result.adjustment.detail.contains("1:16"))
        XCTAssertTrue(result.adjustment.detail.contains("1:15"))
        XCTAssertTrue(result.adjustment.detail.contains("240 g"))
        XCTAssertTrue(result.adjustment.detail.contains("225 g"))
    }

    func testRatioAdviceStopsAtTheMethodBounds() {
        // V60's schema allows 13...20; asking for stronger at 13 has nowhere to go.
        let result = engine.diagnose(input(extraction: 0, strength: -2, ratio: 13))
        XCTAssertEqual(result.adjustment.kind, .lessWater)
        XCTAssertNil(result.adjustment.newValue)
    }

    // MARK: - Closing the loop

    func testLoopOutcomeReportsImprovementHonestly() {
        let adjustment = Adjustment(kind: .grindFiner, headline: "Grind finer", detail: "18 → 16 clicks")
        var previous = Brew(methodID: "v60")
        previous.taste = TasteRecord(rating: 3)
        previous.diagnosis = Diagnosis(ruleID: 4, verdict: "", adjustment: adjustment, explanation: "")

        var better = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        better.taste = TasteRecord(rating: 4)
        XCTAssertEqual(DiagnosisEngine.loopOutcome(current: better, previous: previous),
                       .improved(from: 3, to: 4, change: "grinding finer"))

        var worse = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        worse.taste = TasteRecord(rating: 2)
        XCTAssertEqual(DiagnosisEngine.loopOutcome(current: worse, previous: previous),
                       .worse(from: 3, to: 2, change: "grinding finer"))

        var same = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        same.taste = TasteRecord(rating: 3)
        XCTAssertEqual(DiagnosisEngine.loopOutcome(current: same, previous: previous),
                       .unchanged(rating: 3, change: "grinding finer"))
    }

    func testLoopOutcomeIsNilWhenNothingWasActuallyChanged() {
        var previous = Brew(methodID: "v60")
        previous.taste = TasteRecord(rating: 3)
        previous.diagnosis = Diagnosis(ruleID: 9, verdict: "", adjustment: .none, explanation: "")

        var current = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        current.taste = TasteRecord(rating: 5)
        XCTAssertNil(DiagnosisEngine.loopOutcome(current: current, previous: previous))
    }
}
