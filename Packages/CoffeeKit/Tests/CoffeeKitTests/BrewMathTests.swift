import XCTest
@testable import CoffeeKit

final class BrewMathTests: XCTestCase {

    func testWaterIsDerivedFromDoseAndRatio() {
        XCTAssertEqual(BrewMath.water(dose: 15, ratio: 16), 240)
        XCTAssertEqual(BrewMath.dose(water: 240, ratio: 16), 15)
        XCTAssertEqual(BrewMath.ratio(dose: 15, water: 240), 16)
    }

    func testDivisionByZeroIsSurvivable() {
        XCTAssertEqual(BrewMath.water(dose: 15, ratio: 0), 0)
        XCTAssertEqual(BrewMath.dose(water: 240, ratio: 0), 0)
        XCTAssertEqual(BrewMath.ratio(dose: 0, water: 240), 0)
    }

    /// Targets are cumulative because that is what a scale reads. Making the user
    /// add pours together mid-brew, with wet hands, is a design failure.
    func testCumulativeTargetsCarryForwardThroughNonPourSteps() {
        let targets = BrewMath.cumulativeTargets(steps: BuiltInContent.everydayV60.steps, totalWater: 240)
        XCTAssertEqual(targets, [48, 144, 240, 240, 240])
    }

    func testStepIncrementsNeverGoNegative() {
        let increments = BrewMath.stepIncrements(steps: BuiltInContent.everydayV60.steps, totalWater: 240)
        XCTAssertEqual(increments, [48, 96, 96, 0, 0])
        XCTAssertTrue(increments.allSatisfy { $0 >= 0 })
    }

    /// Steps store water as a fraction of the total precisely so that changing the
    /// dose rescales every target exactly, with no drift.
    func testTargetsRescaleWithDose() {
        let doubled = BrewMath.cumulativeTargets(steps: BuiltInContent.everydayV60.steps, totalWater: 480)
        XCTAssertEqual(doubled, [96, 288, 480, 480, 480])
    }

    func testFinalTargetAlwaysEqualsTotalWater() {
        for recipe in BuiltInContent.recipes {
            let targets = BrewMath.cumulativeTargets(steps: recipe.steps, totalWater: recipe.totalWater)
            XCTAssertEqual(targets.last, recipe.totalWater.rounded(),
                           "\(recipe.name) never reaches its own total water")
        }
    }

    func testFormatting() {
        XCTAssertEqual(BrewMath.formatSeconds(0), "0:00")
        XCTAssertEqual(BrewMath.formatSeconds(65), "1:05")
        XCTAssertEqual(BrewMath.formatSeconds(-5), "0:00")
        XCTAssertEqual(BrewMath.formatGrams(239.6), "240 g")
        XCTAssertEqual(BrewMath.formatRatio(16), "1:16")
        XCTAssertEqual(BrewMath.formatRatio(16.7), "1:16.7")
    }
}

final class GrinderTests: XCTestCase {

    /// The anchor question ("what do you use for pour-over?") exists so the
    /// setting the user actually uses lands in the middle of the normalised scale.
    func testAnchorMapsToTheMiddleOfTheScale() {
        let encore = Grinder.baratzaEncore
        XCTAssertEqual(encore.normalised(fromSetting: encore.pourOverAnchor), 50, accuracy: 0.001)
        XCTAssertEqual(encore.normalised(fromSetting: encore.minSetting), 0, accuracy: 0.001)
        XCTAssertEqual(encore.normalised(fromSetting: encore.maxSetting), 100, accuracy: 0.001)
    }

    func testNormalisationRoundTrips() {
        let encore = Grinder.baratzaEncore
        for setting in stride(from: 1.0, through: 40.0, by: 1.0) {
            let back = encore.setting(fromNormalised: encore.normalised(fromSetting: setting))
            XCTAssertEqual(back, setting, accuracy: 1.0, "setting \(setting) did not survive a round trip")
        }
    }

    func testNormalisationIsMonotonic() {
        let encore = Grinder.baratzaEncore
        var previous = -1.0
        for setting in stride(from: 1.0, through: 40.0, by: 0.5) {
            let value = encore.normalised(fromSetting: setting)
            XCTAssertGreaterThanOrEqual(value, previous)
            previous = value
        }
    }

    func testAdjustmentStepsAreClampedToTheDial() {
        let encore = Grinder.baratzaEncore
        XCTAssertEqual(encore.adjustedSetting(from: 18, steps: -1), 16)
        XCTAssertEqual(encore.adjustedSetting(from: 18, steps: 1), 20)
        XCTAssertEqual(encore.adjustedSetting(from: 1, steps: -1), 1, "cannot grind finer than the grinder allows")
        XCTAssertEqual(encore.adjustedSetting(from: 40, steps: 1), 40)
    }

    func testDegenerateAnchorsDoNotDivideByZero() {
        let broken = Grinder(brand: "", model: "Odd", settingType: .numberedDial,
                             minSetting: 5, maxSetting: 5, pourOverAnchor: 5, adjustmentStep: 1)
        XCTAssertEqual(broken.normalised(fromSetting: 5), 50)
        XCTAssertEqual(broken.setting(fromNormalised: 0), 5)
    }

    func testUnitsAreFormattedPerGrinderType() {
        XCTAssertEqual(Grinder.baratzaEncore.format(16), "16 clicks")
        XCTAssertEqual(Grinder.onedFellowOde2.format(5), "5")
    }
}
