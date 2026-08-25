import XCTest
@testable import CoffeeKit

/// The diagnosis engine is the product. These tests are the reason it lives in a
/// plain Swift package — the whole rule table is verifiable without a simulator,
/// a UI, or a Mac.
final class DiagnosisEngineTests: XCTestCase {

    private let engine = DiagnosisEngine()

    private func input(
        extraction: Int = 0,
        strength: Int = 0,
        milk: Int = 0,
        rating: Int = 3,
        descriptors: [Descriptor] = [],
        method: BrewMethod = BuiltInContent.v60,
        temp: Double = 94,
        totalSeconds: Int? = 180,
        freshness: Freshness? = .peak,
        restDays: Int? = 10,
        grind: GrindControl = .calibrated(.baratzaEncore, setting: 18),
        water: WaterSource = .tap,
        withMilk: Bool = false,
        seenWaterAdvice: Bool = false,
        ratio: Double = 16,
        dose: Double = 15,
        steep: Double? = nil
    ) -> DiagnosisInput {
        var params = BrewParameters([.dose: dose, .ratio: ratio, .waterTemp: temp, .grind: 50])
        if let steep { params[.steepTime] = steep }
        return DiagnosisInput(
            taste: TasteRecord(rating: rating, extraction: extraction, strength: strength,
                               milkCharacter: milk, descriptors: descriptors),
            method: method,
            params: params,
            actualTotalSeconds: totalSeconds,
            beanFreshness: freshness,
            beanRestDays: restDays,
            grindControl: grind,
            waterSource: water,
            withMilk: withMilk,
            hasSeenWaterAdvice: seenWaterAdvice
        )
    }

    private func diagnosis(_ input: DiagnosisInput) throws -> Diagnosis {
        try XCTUnwrap(engine.evaluate(input).diagnosis)
    }

    // MARK: - The grid

    /// The nine cells of the extraction × strength grid, exactly as published.
    /// Because extraction is fixed before strength, the sour column is uniformly
    /// "finer" and the bitter column uniformly "coarser" — only the balanced column
    /// varies. If that stops being true, the grid in the design doc is lying.
    func testGridProducesOneAdjustmentPerCell() throws {
        let expected: [(extraction: Int, strength: Int, kind: Adjustment.Kind)] = [
            (-2,  2, .grindFiner),   (0,  2, .moreWater),  (2,  2, .grindCoarser),
            (-2,  0, .grindFiner),   (0,  0, .none),       (2,  0, .grindCoarser),
            (-2, -2, .grindFiner),   (0, -2, .lessWater),  (2, -2, .grindCoarser)
        ]
        for cell in expected {
            let rating = (cell.extraction == 0 && cell.strength == 0) ? 4 : 2
            let result = try diagnosis(input(extraction: cell.extraction, strength: cell.strength, rating: rating))
            XCTAssertEqual(result.adjustment.kind, cell.kind,
                           "cell (\(cell.extraction), \(cell.strength)) gave \(result.adjustment.kind) via rule \(result.ruleID)")
        }
    }

    func testEveryCombinationResolvesToSomething() throws {
        for extraction in -2...2 {
            for strength in -2...2 {
                for rating in 1...5 {
                    let result = try diagnosis(input(extraction: extraction, strength: strength, rating: rating))
                    XCTAssertFalse(result.verdict.isEmpty)
                    XCTAssertFalse(result.explanation.isEmpty)
                }
            }
        }
    }

    // MARK: - Tier gating

    /// Enforced by the return type, not by convention: there is no path through
    /// `DiagnosisOutcome` that lets a guided method produce a diagnosis, so a
    /// screen cannot promote one by accident.
    func testGuidedMethodsCannotProduceADiagnosis() {
        for method in BuiltInContent.methods where method.supportTier == .guided {
            let outcome = engine.evaluate(input(extraction: -2, strength: -2, method: method))
            XCTAssertNil(outcome.diagnosis, "\(method.name) produced a diagnosis")
            XCTAssertNotNil(outcome.methodNotes, "\(method.name) produced no notes")
        }
    }

    func testReferenceMethodsProduceNothing() {
        for method in BuiltInContent.methods where method.supportTier == .reference {
            XCTAssertEqual(engine.evaluate(input(method: method)), .unsupported)
        }
    }

    func testMethodNotesNameTheLimitOutLoud() {
        for method in BuiltInContent.methods where method.supportTier == .guided {
            let notes = engine.evaluate(input(method: method)).methodNotes
            let headline = try? XCTUnwrap(notes?.headline)
            XCTAssertTrue(headline?.lowercased().contains("don't diagnose") ?? false,
                          "\(method.name) does not state its limit: \(headline ?? "nil")")
            XCTAssertFalse(notes?.notes.isEmpty ?? true)
        }
    }

    func testOnlyTwoMethodsClaimFullDiagnosis() {
        // Breadth is affordable because methods are not supported equally. If this
        // number climbs without rule tables and expert review behind it, the tier
        // model has been quietly abandoned.
        XCTAssertEqual(BuiltInContent.diagnosableMethods.map(\.id).sorted(), ["frenchpress", "v60"])
    }

    // MARK: - Rule ordering

    func testRestingBeanBeatsExtractionAdvice() throws {
        let result = try diagnosis(input(extraction: -2, strength: -1, freshness: .resting, restDays: 2))
        XCTAssertEqual(result.ruleID, 1)
        XCTAssertFalse(result.adjustment.isActionable)
    }

    func testRestingBeanStillCongratulatesABalancedCup() throws {
        let result = try diagnosis(input(rating: 5, freshness: .resting, restDays: 2))
        XCTAssertEqual(result.ruleID, 10)
    }

    func testStaleBeanNeedsAStalingDescriptorToFire() throws {
        let withSignal = try diagnosis(input(rating: 2, descriptors: [.flat], freshness: .stale, restDays: 60))
        XCTAssertEqual(withSignal.ruleID, 2)

        let withoutSignal = try diagnosis(input(extraction: 2, rating: 2, descriptors: [.drying],
                                                freshness: .stale, restDays: 60))
        XCTAssertEqual(withoutSignal.ruleID, 7, "A bitter cup on an old bag is still a brewing problem")
    }

    /// Regression: the temperature rule was originally ordered after the generic
    /// under-extraction rule, which made it unreachable — and gave the wrong advice
    /// besides, since water well below range swamps grind.
    func testCoolWaterIsCheckedBeforeGrind() throws {
        let result = try diagnosis(input(extraction: -2, temp: 82))
        XCTAssertEqual(result.ruleID, 4)
        XCTAssertEqual(result.adjustment.kind, .hotterWater)
    }

    func testSlowDrawdownIsNamedWhenItRanLong() throws {
        let slow = try diagnosis(input(extraction: 2, totalSeconds: 300))
        XCTAssertEqual(slow.ruleID, 6)
        XCTAssertTrue(slow.explanation.contains("5:00"))

        let normal = try diagnosis(input(extraction: 2, totalSeconds: 180))
        XCTAssertEqual(normal.ruleID, 7)
    }

    // MARK: - Water, once

    /// Without the fire-once gate, an RO user who is *also* grinding too coarse is
    /// told "it's your water" after every brew and the loop never advances.
    func testWaterRuleInterruptsOnceThenStepsAside() throws {
        let first = try diagnosis(input(extraction: -2, water: .ro))
        XCTAssertEqual(first.ruleID, 3)
        XCTAssertEqual(first.adjustment.kind, .blendWater)

        let second = try diagnosis(input(extraction: -2, water: .ro, seenWaterAdvice: true))
        XCTAssertEqual(second.ruleID, 5, "Normal grind advice must resume once the point is made")
        XCTAssertEqual(second.adjustment.kind, .grindFiner)
    }

    func testWaterRuleOnlyFiresForStraightRO() throws {
        for source in WaterSource.allCases where source != .ro {
            let result = try diagnosis(input(extraction: -2, water: source))
            XCTAssertNotEqual(result.ruleID, 3, "\(source.label) should not trigger the water rule")
        }
    }

    func testWaterRuleNeedsASymptomToFire() throws {
        // Balanced cup on RO water: nothing to explain, so nothing is said.
        let result = try diagnosis(input(rating: 5, water: .ro))
        XCTAssertEqual(result.ruleID, 10)
    }

    // MARK: - Grind control

    func testCalibratedGrinderAdviceUsesTheUsersOwnDial() throws {
        let result = try diagnosis(input(extraction: -2, grind: .calibrated(.baratzaEncore, setting: 18)))
        XCTAssertEqual(result.adjustment.newGrinderSetting, 16)
        XCTAssertTrue(result.adjustment.detail.contains("18 clicks"))
        XCTAssertTrue(result.adjustment.detail.contains("Baratza Encore"))
    }

    func testUncalibratedGrinderFallsBackToWords() throws {
        let result = try diagnosis(input(extraction: -2, grind: .uncalibrated))
        XCTAssertEqual(result.adjustment.kind, .grindFiner)
        XCTAssertNil(result.adjustment.newGrinderSetting)
        XCTAssertFalse(result.adjustment.detail.contains("→"))
    }

    func testGrindAdviceAtTheEndOfTheDialSaysSo() throws {
        let result = try diagnosis(input(extraction: -2, grind: .calibrated(.baratzaEncore, setting: 1)))
        XCTAssertNil(result.adjustment.newGrinderSetting)
        XCTAssertTrue(result.adjustment.detail.lowercased().contains("finest"))
    }

    /// A pre-ground user cannot act on "grind finer". The engine must reach for
    /// the levers they do have instead of repeating one they don't.
    func testPreGroundIsNeverToldToGrind() throws {
        for extraction in [-2, -1, 1, 2] {
            for method in BuiltInContent.diagnosableMethods {
                let steep = method.param(.steepTime)?.defaultValue
                let result = try diagnosis(input(extraction: extraction, method: method,
                                                 grind: .preGround, steep: steep))
                XCTAssertFalse(result.adjustment.kind.isGrindChange,
                               "\(method.name) told a pre-ground user to \(result.adjustment.kind)")
            }
        }
    }

    func testPreGroundUnderExtractionReachesForTemperature() throws {
        let result = try diagnosis(input(extraction: -2, temp: 90, grind: .preGround))
        XCTAssertEqual(result.adjustment.kind, .hotterWater)
        XCTAssertEqual(result.adjustment.paramKey, .waterTemp)
    }

    /// When temperature has nowhere left to go either, the honest answer is that
    /// the coffee they bought suits a different brewer.
    func testPreGroundOutOfLeversSuggestsADifferentMethod() throws {
        let result = try diagnosis(input(extraction: 2, temp: 80, grind: .preGround))
        XCTAssertEqual(result.adjustment.kind, .tryDifferentMethod)
        let suggested = try XCTUnwrap(result.adjustment.suggestedMethodID)
        let method = try XCTUnwrap(BuiltInContent.method(id: suggested))
        XCTAssertTrue(method.profile.worksWithPreGround)
        XCTAssertTrue(method.canBrew)
        XCTAssertNotEqual(method.id, BuiltInContent.v60.id)
    }

    // MARK: - Immersion reasons differently

    /// The real test of whether the tier model generalises: French press reaches
    /// for time first, where V60 reaches for grind. If both tables were the same
    /// shape, the second one wasn't worth having.
    func testImmersionReachesForTimeBeforeGrind() throws {
        let under = try diagnosis(input(extraction: -2, method: BuiltInContent.frenchPress, steep: 240))
        XCTAssertEqual(under.ruleID, 21)
        XCTAssertEqual(under.adjustment.kind, .steepLonger)
        XCTAssertEqual(under.adjustment.paramKey, .steepTime)

        let over = try diagnosis(input(extraction: 2, method: BuiltInContent.frenchPress, steep: 240))
        XCTAssertEqual(over.ruleID, 22)
        XCTAssertEqual(over.adjustment.kind, .steepShorter)
    }

    func testPourOverStillReachesForGrindFirst() throws {
        let under = try diagnosis(input(extraction: -2))
        XCTAssertEqual(under.ruleID, 5)
        XCTAssertEqual(under.adjustment.kind, .grindFiner)
    }

    func testImmersionFallsBackToGrindAtTheEndOfTheSteepRange() throws {
        let result = try diagnosis(input(extraction: -2, method: BuiltInContent.frenchPress, steep: 600))
        XCTAssertEqual(result.adjustment.kind, .grindFiner, "steep time is capped, so grind is next")
    }

    /// Grit is about fines and the plunge, not extraction — so it is diagnosed on
    /// its own terms rather than being read as over-extraction.
    func testSiltIsDiagnosedAsFinesNotOverExtraction() throws {
        let result = try diagnosis(input(extraction: 0, descriptors: [.silty],
                                         method: BuiltInContent.frenchPress, steep: 240))
        XCTAssertEqual(result.ruleID, 20)
        XCTAssertEqual(result.conceptID, "fines")
    }

    // MARK: - Milk

    /// Milk removes an axis rather than muting a rule. No rule that reads the
    /// extraction axis may fire on a milk drink — reinterpreting an answer the
    /// user gave to a different question is the misdiagnosis the flag prevents.
    func testNoExtractionRuleFiresOnAMilkDrink() throws {
        for extraction in -2...2 {
            for milk in -2...2 {
                let result = try diagnosis(input(extraction: extraction, milk: milk,
                                                 method: BuiltInContent.frenchPress,
                                                 withMilk: true, steep: 240))
                XCTAssertFalse([5, 6, 7, 20, 21, 22].contains(result.ruleID),
                               "extraction rule \(result.ruleID) fired on a milk drink")
            }
        }
    }

    func testHarshMilkDrinkBacksOffRatherThanGrinding() throws {
        let result = try diagnosis(input(milk: -2, method: BuiltInContent.frenchPress,
                                         withMilk: true, steep: 240))
        XCTAssertEqual(result.ruleID, 30)
        XCTAssertEqual(result.adjustment.kind, .steepShorter)
        XCTAssertEqual(result.conceptID, "milk")
    }

    /// Flat through milk is nearly always strength, not extraction — milk dilutes
    /// before it masks.
    func testFlatMilkDrinkIsTreatedAsStrength() throws {
        let result = try diagnosis(input(milk: 2, method: BuiltInContent.frenchPress,
                                         withMilk: true, steep: 240))
        XCTAssertEqual(result.ruleID, 31)
        XCTAssertEqual(result.adjustment.kind, .lessWater)
    }

    func testMilkDrinkIgnoresAStaleExtractionAnswer() throws {
        // extraction says "very sour" but the drink has milk: the answer is from a
        // question we didn't ask, and must not be read.
        let result = try diagnosis(input(extraction: -2, milk: 0, rating: 5,
                                         method: BuiltInContent.frenchPress,
                                         withMilk: true, steep: 240))
        XCTAssertEqual(result.ruleID, 10, "a balanced milk drink the user liked")
    }

    func testBalanceIsJudgedOnWhicheverAxisWasAsked() {
        let record = TasteRecord(rating: 4, extraction: -2, strength: 0, milkCharacter: 0)
        XCTAssertTrue(record.isBalanced(withMilk: true))
        XCTAssertFalse(record.isBalanced(withMilk: false))
    }

    // MARK: - Closing the loop

    func testLoopOutcomeReportsHonestly() {
        let adjustment = Adjustment(kind: .grindFiner, headline: "Grind finer", detail: "18 → 16 clicks")
        var previous = Brew(methodID: "v60")
        previous.taste = TasteRecord(rating: 3)
        previous.diagnosis = Diagnosis(ruleID: 5, verdict: "", adjustment: adjustment, explanation: "")

        var better = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        better.taste = TasteRecord(rating: 4)
        XCTAssertEqual(DiagnosisEngine.loopOutcome(current: better, previous: previous),
                       .improved(from: 3, to: 4, change: "grinding finer"))

        var worse = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        worse.taste = TasteRecord(rating: 2)
        XCTAssertEqual(DiagnosisEngine.loopOutcome(current: worse, previous: previous),
                       .worse(from: 3, to: 2, change: "grinding finer"))
    }

    func testLoopOutcomeIsNilWhenNothingWasChanged() {
        var previous = Brew(methodID: "v60")
        previous.taste = TasteRecord(rating: 3)
        previous.diagnosis = Diagnosis(ruleID: 10, verdict: "", adjustment: .none, explanation: "")

        var current = Brew(methodID: "v60", adjustedFromBrewID: previous.id)
        current.taste = TasteRecord(rating: 5)
        XCTAssertNil(DiagnosisEngine.loopOutcome(current: current, previous: previous))
    }
}
