import XCTest
@testable import CoffeeKit

final class BeanFreshnessTests: XCTestCase {

    private func bean(roastLevel: RoastLevel, daysAgo: Int) -> Bean {
        Bean(name: "Test",
             roastLevel: roastLevel,
             roastDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()))
    }

    /// Light roasts degas slower and hold longer. Using one window for every roast
    /// would misfire the degassing rule on most of what our users actually buy.
    func testFreshnessWindowsDifferByRoastLevel() {
        XCTAssertEqual(bean(roastLevel: .light, daysAgo: 5).freshness(), .resting)
        XCTAssertEqual(bean(roastLevel: .medium, daysAgo: 5).freshness(), .peak)
        XCTAssertEqual(bean(roastLevel: .dark, daysAgo: 5).freshness(), .peak)

        XCTAssertEqual(bean(roastLevel: .light, daysAgo: 30).freshness(), .fading)
        XCTAssertEqual(bean(roastLevel: .dark, daysAgo: 30).freshness(), .stale)
    }

    func testFreshnessIsUnknownWithoutARoastDate() {
        let undated = Bean(name: "Mystery bag")
        XCTAssertNil(undated.freshness())
        XCTAssertNil(undated.restDays())
    }

    func testFutureRoastDatesDoNotProduceNegativeRestDays() {
        let future = Bean(name: "Time traveller",
                          roastDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()))
        XCTAssertEqual(future.restDays(), 0)
    }

    func testOnlyRestingBlocksDiagnosis() {
        XCTAssertFalse(Freshness.resting.isDiagnosable)
        XCTAssertTrue(Freshness.peak.isDiagnosable)
        XCTAssertTrue(Freshness.fading.isDiagnosable)
        XCTAssertTrue(Freshness.stale.isDiagnosable)
    }
}

final class BrewParametersTests: XCTestCase {

    /// Parameters are a method-scoped bag rather than fixed columns, so espresso
    /// can be added later as an addition instead of a migration.
    func testParametersEncodeAsAReadableObject() throws {
        let params = BrewParameters([.dose: 15, .ratio: 16])
        let data = try JSONEncoder().encode(params)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"dose\""), "export must be human-readable: \(json)")
        XCTAssertTrue(json.contains("\"ratio\""))

        let decoded = try JSONDecoder().decode(BrewParameters.self, from: data)
        XCTAssertEqual(decoded, params)
    }

    func testEspressoParametersRoundTripThroughTheSameType() {
        var shot = BrewParameters()
        shot[.dose] = 18
        shot[.yield] = 36
        shot[.shotTime] = 28
        XCTAssertEqual(shot[.yield], 36)
        XCTAssertNil(shot[.bloomWater], "a shot has no bloom, and asking for one is not an error")
    }

    func testChangedKeysFindsPlannedVersusActualDrift() {
        let planned = BrewParameters([.dose: 15, .ratio: 16, .waterTemp: 94])
        let actual = BrewParameters([.dose: 15.4, .ratio: 16, .waterTemp: 94])
        XCTAssertEqual(planned.changedKeys(comparedTo: actual), [.dose])
    }

    func testChangedKeysIgnoresFloatingPointNoise() {
        let a = BrewParameters([.ratio: 16.0])
        let b = BrewParameters([.ratio: 16.00001])
        XCTAssertTrue(a.changedKeys(comparedTo: b).isEmpty)
    }

    func testChangedKeysReportsKeysPresentOnOnlyOneSide() {
        let planned = BrewParameters([.dose: 15])
        let actual = BrewParameters([.dose: 15, .waterTemp: 92])
        XCTAssertEqual(planned.changedKeys(comparedTo: actual), [.waterTemp])
    }

    func testParamDefClamps() {
        let def = ParamDef(key: .ratio, unit: .ratio, minimum: 13, maximum: 20, step: 0.5, defaultValue: 16)
        XCTAssertEqual(def.clamp(12), 13)
        XCTAssertEqual(def.clamp(25), 20)
        XCTAssertEqual(def.clamp(16), 16)
    }
}

final class SharedStoreTests: XCTestCase {

    /// A store pointed at its own temporary directory. Tests must not depend on
    /// whatever ambient cache directory the host happens to provide — that was
    /// the original failure here, and it would have been just as opaque on
    /// someone's laptop.
    private var store: SharedStore!
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SharedStoreTests-\(UUID().uuidString)", isDirectory: true)
        store = SharedStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        store = nil
        directory = nil
        try super.tearDownWithError()
    }

    func testSnapshotSurvivesARoundTrip() throws {
        try store.write(WidgetSnapshot.placeholder)

        let loaded = store.load()
        XCTAssertEqual(loaded.lastBrew?.recipeName, "Everyday V60")
        XCTAssertEqual(loaded.pendingAdjustment?.headline, "Grind finer")
        XCTAssertEqual(loaded.pendingAdjustment?.kind, .grindFiner)
        XCTAssertEqual(loaded.activeBean?.freshness, .peak)
        XCTAssertEqual(loaded.totalBrews, 24)
        XCTAssertTrue(loaded.hasBrewed)
    }

    /// The App Group container is created by the system, but a fallback directory
    /// may not exist yet — writing has to create it rather than silently failing.
    func testWritingCreatesTheDirectory() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
        try store.write(.placeholder)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    /// A widget reading a missing or corrupt file must render an empty state, not
    /// crash — a crashed widget shows as a blank tile, which users read as a
    /// broken app.
    func testMissingSnapshotReadsAsEmptyRatherThanFailing() {
        XCTAssertFalse(store.load().hasBrewed)
    }

    func testCorruptSnapshotReadsAsEmptyRatherThanFailing() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("this is not json".utf8).write(to: store.fileURL)
        XCTAssertFalse(store.load().hasBrewed)
    }

    func testClearRemovesTheSnapshot() throws {
        try store.write(.placeholder)
        store.clear()
        XCTAssertFalse(store.load().hasBrewed)
    }

    func testBeanSummaryDerivesFreshnessAtSnapshotTime() {
        let bean = Bean(name: "Guji", roaster: "Assembly", roastLevel: .light,
                        roastDate: Calendar.current.date(byAdding: .day, value: -9, to: Date()))
        let summary = BeanSummary(bean: bean)
        XCTAssertEqual(summary.restDays, 9)
        XCTAssertEqual(summary.freshness, .peak)
        XCTAssertEqual(summary.roaster, "Assembly")
    }
}

/// The journal is the one object in this app that cannot be regenerated, so every
/// schema change has to be additive and every new key needs an answer for records
/// that predate it. These tests are the guard on that promise.
final class JournalMigrationTests: XCTestCase {

    /// A brew written before water, milk and the milk axis existed.
    private let legacyBrewJSON = """
    {
      "id": "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
      "startedAt": "2026-01-05T08:30:00Z",
      "methodID": "v60",
      "recipeID": "v60-everyday",
      "params": { "dose": 15, "ratio": 16, "waterTemp": 94, "grind": 50 },
      "plannedParams": { "dose": 15, "ratio": 16, "waterTemp": 94, "grind": 50 },
      "actualTotalSeconds": 185,
      "taste": { "rating": 4, "extraction": -1, "strength": 0, "descriptors": ["sharp"] }
    }
    """

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testLegacyBrewDecodesWithSensibleDefaults() throws {
        let brew = try decoder().decode(Brew.self, from: Data(legacyBrewJSON.utf8))
        XCTAssertEqual(brew.methodID, "v60")
        XCTAssertEqual(brew.waterSource, .unknown, "an unknown water source must not fabricate one")
        XCTAssertFalse(brew.withMilk)
        XCTAssertEqual(brew.taste?.milkCharacter, 0)
        XCTAssertEqual(brew.taste?.extraction, -1)
    }

    /// An unknown water source must never trigger the water rule — inventing a
    /// cause for a brew that predates the question would be worse than silence.
    func testLegacyBrewIsNeverDiagnosedAsAWaterProblem() throws {
        let brew = try decoder().decode(Brew.self, from: Data(legacyBrewJSON.utf8))
        let taste = try XCTUnwrap(brew.taste)
        let diagnosis = DiagnosisEngine().diagnose(DiagnosisInput(
            taste: taste,
            method: BuiltInContent.v60,
            params: brew.params,
            grindControl: .uncalibrated,
            waterSource: brew.waterSource,
            withMilk: brew.withMilk
        ))
        XCTAssertNotEqual(diagnosis?.ruleID, 3)
    }

    func testRoundTripThroughEncodingPreservesNewFields() throws {
        var brew = Brew(methodID: "moka", waterSource: .ro, withMilk: true)
        brew.taste = TasteRecord(rating: 3, milkCharacter: -2)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(brew)
        let decoded = try decoder().decode(Brew.self, from: data)

        XCTAssertEqual(decoded.waterSource, .ro)
        XCTAssertTrue(decoded.withMilk)
        XCTAssertEqual(decoded.taste?.milkCharacter, -2)
    }
}

final class TasteAxisTests: XCTestCase {

    /// A milk brew's `extraction` is a default, not an answer — the user was
    /// asked a different question. Anything that reads a taste record has to
    /// consult `withMilk` first, or it will report an unanswered question as
    /// "balanced".
    func testTheUnaskedAxisIsNeverMeaningful() {
        let milkRecord = TasteRecord(rating: 3, extraction: 0, strength: 0, milkCharacter: -2)
        XCTAssertFalse(milkRecord.isBalanced(withMilk: true), "the milk axis says harsh")
        XCTAssertTrue(milkRecord.isBalanced(withMilk: false), "which is why reading the wrong one lies")
    }

    func testBalanceFollowsWhicheverAxisWasAsked() {
        let blackRecord = TasteRecord(rating: 3, extraction: 2, strength: 0, milkCharacter: 0)
        XCTAssertFalse(blackRecord.isBalanced(withMilk: false))
        XCTAssertTrue(blackRecord.isBalanced(withMilk: true))
    }
}

final class TasteRecordTests: XCTestCase {

    func testAxesAndRatingAreClampedToTheirRanges() {
        let record = TasteRecord(rating: 9, extraction: -7, strength: 12)
        XCTAssertEqual(record.rating, 5)
        XCTAssertEqual(record.extraction, -2)
        XCTAssertEqual(record.strength, 2)
    }

    func testBalancedMeansBothAxesCentred() {
        XCTAssertTrue(TasteRecord(rating: 4).isBalanced)
        XCTAssertFalse(TasteRecord(rating: 4, extraction: 1).isBalanced)
        XCTAssertFalse(TasteRecord(rating: 4, strength: -1).isBalanced)
    }
}
