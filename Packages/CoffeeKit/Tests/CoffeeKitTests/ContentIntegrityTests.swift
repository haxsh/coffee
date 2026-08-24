import XCTest
@testable import CoffeeKit

/// A concept link that goes nowhere fails in the exact moment a user asked for
/// help. Catching that here means it can never ship.
final class ContentIntegrityTests: XCTestCase {

    func testConceptIDsAreUnique() {
        let ids = Concepts.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate concept ids: \(ids)")
    }

    func testEveryRelatedConceptResolves() {
        for concept in Concepts.all {
            for related in concept.relatedConceptIDs {
                XCTAssertNotNil(Concepts.concept(id: related),
                                "\(concept.id) links to missing concept '\(related)'")
            }
        }
    }

    func testEveryRecipeStepConceptResolves() {
        for recipe in BuiltInContent.recipes {
            for step in recipe.steps {
                guard let id = step.conceptID else { continue }
                XCTAssertNotNil(Concepts.concept(id: id),
                                "\(recipe.name)/\(step.id) links to missing concept '\(id)'")
            }
        }
    }

    func testEveryMethodConceptResolves() {
        for method in BuiltInContent.methods {
            for id in method.conceptIDs {
                XCTAssertNotNil(Concepts.concept(id: id), "\(method.name) links to missing concept '\(id)'")
            }
        }
    }

    func testEveryDescriptorConceptResolves() {
        for descriptor in Descriptor.allCases {
            guard let id = descriptor.conceptID else { continue }
            XCTAssertNotNil(Concepts.concept(id: id), "descriptor '\(descriptor.rawValue)' links to missing concept '\(id)'")
        }
    }

    /// Sweeps the engine across every reachable rule and asserts each concept it
    /// hands back actually exists.
    func testEveryDiagnosisConceptResolves() {
        let engine = DiagnosisEngine()
        let freshnesses: [Freshness?] = [nil, .resting, .peak, .fading, .stale]
        let temps: [Double] = [82, 94]
        let times: [Int?] = [nil, 180, 300]

        for extraction in -2...2 {
            for strength in -2...2 {
                for rating in 1...5 {
                    for freshness in freshnesses {
                        for temp in temps {
                            for time in times {
                                let result = engine.diagnose(DiagnosisInput(
                                    taste: TasteRecord(rating: rating, extraction: extraction,
                                                       strength: strength, descriptors: [.flat]),
                                    method: BuiltInContent.v60,
                                    params: BrewParameters([.dose: 15, .ratio: 16, .waterTemp: temp, .grind: 50]),
                                    actualTotalSeconds: time,
                                    beanFreshness: freshness,
                                    beanRestDays: 10,
                                    grinder: .baratzaEncore,
                                    grinderSetting: 18
                                ))
                                if let id = result.conceptID {
                                    XCTAssertNotNil(Concepts.concept(id: id),
                                                    "rule \(result.ruleID) links to missing concept '\(id)'")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testRecipeStepsAreOrderedAndContiguous() {
        for recipe in BuiltInContent.recipes {
            var lastEnd = -1
            for step in recipe.steps {
                XCTAssertGreaterThanOrEqual(step.startSeconds, lastEnd,
                                            "\(recipe.name)/\(step.id) starts before the previous step ends")
                XCTAssertGreaterThan(step.durationSeconds, 0, "\(recipe.name)/\(step.id) has no duration")
                lastEnd = step.endSeconds
            }
        }
    }

    func testRecipeWaterFractionsNeverGoBackwards() {
        for recipe in BuiltInContent.recipes {
            var previous = 0.0
            for step in recipe.steps {
                guard let fraction = step.cumulativeWaterFraction else { continue }
                XCTAssertGreaterThanOrEqual(fraction, previous,
                                            "\(recipe.name)/\(step.id) asks the user to pour water back out")
                previous = fraction
            }
            XCTAssertEqual(previous, 1.0, accuracy: 0.001, "\(recipe.name) never reaches 100% of its water")
        }
    }

    func testEveryRecipeFinishesInsideItsMethodsExpectedWindow() {
        for recipe in BuiltInContent.recipes {
            guard let method = BuiltInContent.method(id: recipe.methodID) else {
                return XCTFail("\(recipe.name) references unknown method \(recipe.methodID)")
            }
            XCTAssertTrue(method.expectedTotalSeconds.contains(recipe.totalSeconds),
                          "\(recipe.name) runs \(recipe.totalSeconds)s, outside \(method.expectedTotalSeconds)")
        }
    }

    func testRecipeParametersRespectTheirMethodSchema() {
        for recipe in BuiltInContent.recipes {
            guard let method = BuiltInContent.method(id: recipe.methodID) else { continue }
            for key in recipe.parameters.keys {
                guard let def = method.param(key) else {
                    return XCTFail("\(recipe.name) sets '\(key.rawValue)', which \(method.name) does not have")
                }
                let value = recipe.parameters[key] ?? 0
                XCTAssertTrue((def.minimum...def.maximum).contains(value),
                              "\(recipe.name).\(key.rawValue) = \(value) is outside \(def.minimum)...\(def.maximum)")
            }
        }
    }

    /// The starter recipe is the first thing a new user brews. If it fails, they
    /// never reach the loop at all.
    func testStarterRecipeIsUnlockedAndForgiving() {
        XCTAssertFalse(BuiltInContent.starterRecipe.isLocked)
        XCTAssertEqual(BuiltInContent.starterRecipe.methodID, BuiltInContent.v60.id)
        XCTAssertFalse(BuiltInContent.v60.isLocked)
    }
}
