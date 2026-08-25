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
    /// hands back actually exists. A concept link that goes nowhere fails in the
    /// exact moment a user asked for help.
    func testEveryDiagnosisConceptResolves() {
        let engine = DiagnosisEngine()
        let freshnesses: [Freshness?] = [nil, .resting, .peak, .fading, .stale]
        let grinds: [GrindControl] = [.calibrated(.baratzaEncore, setting: 18), .uncalibrated, .preGround]

        for method in BuiltInContent.diagnosableMethods {
            for extraction in -2...2 {
                for strength in -2...2 {
                    for milk in [-2, 0, 2] {
                        for withMilk in [false, true] {
                            for freshness in freshnesses {
                                for temp in [82.0, 94.0] {
                                    for water in WaterSource.allCases {
                                        for grind in grinds {
                                            var params = BrewParameters([
                                                .dose: 15, .ratio: 16, .waterTemp: temp, .grind: 50
                                            ])
                                            if let steep = method.param(.steepTime)?.defaultValue {
                                                params[.steepTime] = steep
                                            }
                                            let outcome = engine.evaluate(DiagnosisInput(
                                                taste: TasteRecord(rating: 3, extraction: extraction,
                                                                   strength: strength, milkCharacter: milk,
                                                                   descriptors: [.flat, .silty]),
                                                method: method,
                                                params: params,
                                                actualTotalSeconds: 300,
                                                beanFreshness: freshness,
                                                beanRestDays: 10,
                                                grindControl: grind,
                                                waterSource: water,
                                                withMilk: withMilk
                                            ))
                                            guard let id = outcome.diagnosis?.conceptID else { continue }
                                            XCTAssertNotNil(Concepts.concept(id: id),
                                                            "a rule links to missing concept '\(id)'")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testEveryMethodNoteConceptResolves() {
        for method in BuiltInContent.methods where method.supportTier == .guided {
            let notes = MethodNotes.forMethod(method)
            XCTAssertFalse(notes.notes.isEmpty, "\(method.name) has no notes")
            for note in notes.notes {
                guard let id = note.conceptID else { continue }
                XCTAssertNotNil(Concepts.concept(id: id),
                                "\(method.name) note '\(note.title)' links to missing concept '\(id)'")
            }
        }
    }

    // MARK: - Tiers

    func testEveryMethodHasContentMatchingItsTier() {
        for method in BuiltInContent.methods {
            switch method.supportTier {
            case .full, .guided:
                XCTAssertFalse(method.paramSchema.isEmpty, "\(method.name) can be brewed but has no parameters")
                XCTAssertFalse(BuiltInContent.recipes(forMethod: method.id).isEmpty,
                               "\(method.name) can be brewed but has no recipe")
                XCTAssertGreaterThan(method.expectedTotalSeconds.upperBound, 0)
            case .reference:
                XCTAssertTrue(method.paramSchema.isEmpty,
                              "\(method.name) is reference-only but declares parameters")
                XCTAssertTrue(BuiltInContent.recipes(forMethod: method.id).isEmpty,
                              "\(method.name) is reference-only but has a recipe — that implies a timer we don't have")
            }
        }
    }

    /// A reference method's only job is its overview card. If that doesn't resolve
    /// the branch is a dead end with nothing at the end of it.
    func testEveryReferenceMethodHasAnOverviewConcept() {
        for method in BuiltInContent.methods where method.supportTier == .reference {
            let id = try? XCTUnwrap(method.conceptIDs.first)
            XCTAssertNotNil(Concepts.concept(id: id ?? ""),
                            "\(method.name) has no overview concept")
        }
    }

    func testEveryMethodProfileIsInRange() {
        for method in BuiltInContent.methods {
            let profile = method.profile
            for (name, value) in [("effort", profile.effort), ("time", profile.time),
                                  ("gearCost", profile.gearCost), ("forgiveness", profile.forgiveness)] {
                XCTAssertTrue((1...5).contains(value), "\(method.name).\(name) = \(value)")
            }
            XCTAssertFalse(profile.tastesLike.isEmpty, "\(method.name) doesn't say what it tastes like")
        }
    }

    func testMethodIDsAreUnique() {
        let ids = BuiltInContent.methods.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testRecipeIDsAreUnique() {
        let ids = BuiltInContent.recipes.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// Milk is scoped to the methods it actually appears in, so the majority of
    /// brews never pay for the question.
    func testMilkIsScopedToMilkMethods() {
        let milkMethods = BuiltInContent.methods.filter(\.takesMilk).map(\.id).sorted()
        XCTAssertEqual(milkMethods, ["espresso", "instant", "moka", "southindianfilter"])
        XCTAssertFalse(BuiltInContent.v60.takesMilk)
        XCTAssertFalse(BuiltInContent.frenchPress.takesMilk)
    }

    /// Every brewable method offers something gentle to start on. A first attempt
    /// on an unfamiliar brewer should not be the high-clarity recipe.
    func testEveryBrewableMethodHasAGentlestRecipe() {
        for method in BuiltInContent.brewableMethods {
            XCTAssertNotNil(BuiltInContent.gentlestRecipe(forMethod: method.id), method.name)
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
