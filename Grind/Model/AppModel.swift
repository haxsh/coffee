import Foundation
import Observation
import WidgetKit
import CoffeeKit

@Observable
@MainActor
final class AppModel {
    private(set) var data: AppData
    private let store = AppDataStore()
    private let engine = DiagnosisEngine()

    init(data: AppData? = nil) {
        let store = AppDataStore()
        self.data = data ?? store.load()
    }

    // MARK: - Derived reads

    var brewsNewestFirst: [Brew] {
        data.brews.sorted { $0.startedAt > $1.startedAt }
    }

    var lastBrew: Brew? { brewsNewestFirst.first }

    var activeBeans: [Bean] {
        data.beans.filter { !$0.isArchived }
            .sorted { ($0.roastDate ?? .distantPast) > ($1.roastDate ?? .distantPast) }
    }

    var selectedGrinder: Grinder? {
        guard let id = data.selectedGrinderID else { return nil }
        return data.grinders.first { $0.id == id }
    }

    var allRecipes: [Recipe] { BuiltInContent.recipes + data.userRecipes }

    func recipe(id: String?) -> Recipe? {
        guard let id else { return nil }
        return allRecipes.first { $0.id == id }
    }

    func bean(id: UUID?) -> Bean? {
        guard let id else { return nil }
        return data.beans.first { $0.id == id }
    }

    func brew(id: UUID?) -> Brew? {
        guard let id else { return nil }
        return data.brews.first { $0.id == id }
    }

    func brews(forBean beanID: UUID) -> [Brew] {
        brewsNewestFirst.filter { $0.beanID == beanID }
    }

    /// The best cup you ever made from a bag, with the numbers that made it.
    func bestBrew(forBean beanID: UUID) -> Brew? {
        brews(forBean: beanID)
            .filter { $0.taste != nil }
            .max { ($0.taste?.rating ?? 0) < ($1.taste?.rating ?? 0) }
    }

    func pendingAdjustment(forMethod methodID: String) -> PendingAdjustment? {
        data.pendingAdjustments[methodID]
    }

    /// The recipe Brew Home offers first. Falls back to the forgiving starter so
    /// a brand-new user's first brew cannot fail.
    var suggestedRecipe: Recipe {
        recipe(id: data.lastRecipeID) ?? BuiltInContent.starterRecipe
    }

    // MARK: - Mutations

    func addBrew(_ brew: Brew) {
        data.brews.append(brew)
        data.lastRecipeID = brew.recipeID ?? data.lastRecipeID
        if let beanID = brew.beanID { data.lastBeanID = beanID }
        persist()
    }

    func updateBrew(_ brew: Brew) {
        guard let index = data.brews.firstIndex(where: { $0.id == brew.id }) else { return }
        data.brews[index] = brew
        persist()
    }

    func deleteBrew(_ brew: Brew) {
        data.brews.removeAll { $0.id == brew.id }
        persist()
    }

    func upsertBean(_ bean: Bean) {
        if let index = data.beans.firstIndex(where: { $0.id == bean.id }) {
            data.beans[index] = bean
        } else {
            data.beans.append(bean)
        }
        persist()
    }

    func deleteBean(_ bean: Bean) {
        data.beans.removeAll { $0.id == bean.id }
        persist()
    }

    func upsertGrinder(_ grinder: Grinder, makeSelected: Bool = true) {
        if let index = data.grinders.firstIndex(where: { $0.id == grinder.id }) {
            data.grinders[index] = grinder
        } else {
            data.grinders.append(grinder)
        }
        if makeSelected { data.selectedGrinderID = grinder.id }
        persist()
    }

    func selectGrinder(_ grinder: Grinder) {
        data.selectedGrinderID = grinder.id
        persist()
    }

    func completeOnboarding(waterSource: WaterSource = .unknown, buysPreGround: Bool = false) {
        data.hasOnboarded = true
        data.waterSource = waterSource
        data.buysPreGround = buysPreGround
        persist()
    }

    /// Remembered per method, so the milk question costs zero taps in the steady
    /// state: a moka drinker who always adds milk answers it once, ever.
    func defaultMilk(forMethod methodID: String) -> Bool {
        data.milkDefaults[methodID] ?? false
    }

    func rememberMilk(_ withMilk: Bool, forMethod methodID: String) {
        guard data.milkDefaults[methodID] != withMilk else { return }
        data.milkDefaults[methodID] = withMilk
        persist()
    }

    // MARK: - The loop

    /// The engine's full answer, including the tier 2 and tier 3 cases. The UI
    /// routes on this rather than on the method, so a screen cannot promote a
    /// method into a diagnosis the engine never produced.
    func evaluate(_ brew: Brew) -> DiagnosisOutcome? {
        guard let taste = brew.taste,
              let method = BuiltInContent.method(id: brew.methodID)
        else { return nil }

        return engine.evaluate(DiagnosisInput(
            taste: taste,
            method: method,
            params: brew.params,
            actualTotalSeconds: brew.actualTotalSeconds,
            beanFreshness: brew.beanFreshness,
            beanRestDays: brew.beanRestDays,
            grindControl: grindControl(for: brew),
            waterSource: brew.waterSource,
            withMilk: brew.withMilk,
            hasSeenWaterAdvice: data.hasSeenWaterAdvice
        ))
    }

    func diagnose(_ brew: Brew) -> Diagnosis? {
        evaluate(brew)?.diagnosis
    }

    /// What this user could actually change about their grind on this brew.
    private func grindControl(for brew: Brew) -> GrindControl {
        if data.buysPreGround { return .preGround }
        let grinder = data.grinders.first { $0.id == brew.grinderID } ?? selectedGrinder
        guard let grinder, let setting = brew.grinderSetting else { return .uncalibrated }
        return .calibrated(grinder, setting: setting)
    }

    /// The payoff: did the change the user made actually help?
    func loopOutcome(for brew: Brew) -> LoopOutcome? {
        guard let previousID = brew.adjustedFromBrewID,
              let previous = self.brew(id: previousID)
        else { return nil }
        return DiagnosisEngine.loopOutcome(current: brew, previous: previous)
    }

    func applyAdjustment(_ adjustment: Adjustment, from brew: Brew) {
        guard adjustment.isActionable else { return }
        data.pendingAdjustments[brew.methodID] = PendingAdjustment(
            sourceBrewID: brew.id,
            methodID: brew.methodID,
            adjustment: adjustment
        )
        persist()
    }

    /// The water rule interrupts once and then steps aside. Recording that here
    /// rather than in the engine keeps the engine pure and the gate testable.
    func markWaterAdviceSeen() {
        guard !data.hasSeenWaterAdvice else { return }
        data.hasSeenWaterAdvice = true
        persist()
    }

    /// The exploration loop's progress object. Derived from the journal, never
    /// stored — a stored copy could disagree with it after a deleted brew.
    var methodsTried: Set<String> {
        Set(data.brews.map(\.methodID))
    }

    /// The north star, made visible: the most brews logged on any single method.
    var handoffProgress: Int {
        Dictionary(grouping: data.brews, by: \.methodID)
            .values.map(\.count).max() ?? 0
    }

    func clearPendingAdjustment(forMethod methodID: String) {
        data.pendingAdjustments[methodID] = nil
        persist()
    }

    // MARK: - Export

    func exportCSV() -> String { store.exportCSV(data) }
    func exportJSON() -> Data? { store.exportJSON(data) }

    // MARK: - Persistence + widgets

    func persist() {
        store.save(data)
        publishWidgetSnapshot()
    }

    /// Projects the document into the small file the widgets read, then nudges
    /// WidgetKit. Called on every mutation — the widget should never show a state
    /// the app has already moved past.
    private func publishWidgetSnapshot() {
        let last = lastBrew
        let recipeForLast = recipe(id: last?.recipeID)
        let beanForLast = bean(id: last?.beanID)

        let brewSummary = last.map { brew in
            BrewSummary(
                brewID: brew.id,
                methodID: brew.methodID,
                methodName: BuiltInContent.method(id: brew.methodID)?.name ?? brew.methodID,
                recipeID: brew.recipeID,
                recipeName: recipeForLast?.name ?? "Freestyle brew",
                beanName: beanForLast?.name,
                rating: brew.taste?.rating,
                brewedAt: brew.startedAt
            )
        }

        let pending = last.flatMap { data.pendingAdjustments[$0.methodID] }
            ?? data.pendingAdjustments.values.sorted { $0.createdAt > $1.createdAt }.first

        let snapshot = WidgetSnapshot(
            lastBrew: brewSummary,
            pendingAdjustment: pending.map { AdjustmentSummary($0.adjustment) },
            activeBean: activeBeans.first.map { BeanSummary(bean: $0) },
            totalBrews: data.brews.count,
            updatedAt: Date()
        )

        SharedStore.shared.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
