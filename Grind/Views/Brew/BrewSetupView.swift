import SwiftUI
import CoffeeKit

/// The pre-flight. Every field is pre-filled; a user who changes nothing can hit
/// Start and get a good cup.
///
/// The only number most people actually touch is the dose — so water recomputes
/// live and visibly the moment it changes, which is the entire reason to use an
/// app here instead of a video.
struct BrewSetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe

    @State private var dose: Double = 15
    @State private var ratio: Double = 16
    @State private var waterTemp: Double = 94
    @State private var steepTime: Double = 240
    @State private var grinderSetting: Double = 18
    @State private var beanID: UUID?
    @State private var loaded = false

    private var method: BrewMethod { BuiltInContent.method(id: recipe.methodID) ?? BuiltInContent.v60 }
    private var grinder: Grinder? { model.selectedGrinder }
    private var pending: PendingAdjustment? { model.pendingAdjustment(forMethod: recipe.methodID) }
    private var water: Double { BrewMath.water(dose: dose, ratio: ratio) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Coffee", selection: $beanID) {
                        Text("Not tracking this one").tag(UUID?.none)
                        ForEach(model.activeBeans) { bean in
                            Text(bean.name).tag(UUID?.some(bean.id))
                        }
                    }
                    if let bean = model.bean(id: beanID) {
                        HStack {
                            Text("Freshness").foregroundStyle(Theme.muted)
                            Spacer()
                            FreshnessBadge(freshness: bean.freshness(), restDays: bean.restDays())
                        }
                    }
                } header: {
                    Text("Coffee")
                } footer: {
                    // Never block a brew on inventory data.
                    Text("Optional. A roast date makes the advice you get afterwards more accurate.")
                }

                Section("Brew") {
                    LabeledContent("Dose") {
                        Stepper(BrewMath.formatGrams(dose), value: $dose, in: doseRange, step: 0.5)
                            .monospacedDigit()
                    }
                    LabeledContent("Ratio") {
                        Stepper(BrewMath.formatRatio(ratio), value: $ratio, in: ratioRange, step: 0.5)
                            .monospacedDigit()
                    }
                    LabeledContent("Water") {
                        Text(BrewMath.formatGrams(water))
                            .monospacedDigit()
                            .foregroundStyle(Theme.water)
                            .font(.body.weight(.semibold))
                            .contentTransition(.numericText())
                    }
                    LabeledContent("Water temp") {
                        Stepper("\(Int(waterTemp)) °C", value: $waterTemp, in: 80...100, step: 1)
                            .monospacedDigit()
                    }
                    // Immersion's primary lever, where pour-over has grind. It has
                    // to be reachable, or "steep longer" is advice with nothing
                    // behind it.
                    if let def = method.param(.steepTime) {
                        LabeledContent("Steep") {
                            Stepper(BrewMath.formatSeconds(Int(steepTime)),
                                    value: $steepTime,
                                    in: def.minimum...def.maximum,
                                    step: def.step)
                                .monospacedDigit()
                        }
                    }
                }

                Section {
                    if let grinder {
                        LabeledContent("Grind") {
                            Stepper(grinder.format(grinderSetting),
                                    value: $grinderSetting,
                                    in: grinder.minSetting...grinder.maxSetting,
                                    step: grinder.settingType == .stepless ? 0.1 : 1)
                                .monospacedDigit()
                        }
                    } else {
                        NavigationLink("Set up your grinder") { GrinderSetupView() }
                    }

                    if let pending {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars").foregroundStyle(Theme.water)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Applying your adjustment")
                                    .font(.footnote.weight(.semibold))
                                Text(pending.adjustment.detail)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                    }
                } header: {
                    Text("Grind")
                } footer: {
                    if grinder == nil {
                        Text("Without a grinder we can't tell you \"18 → 16 clicks\" — only \"one step finer\".")
                    }
                }

                Section("Steps") {
                    ForEach(Array(effectiveRecipe.steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text(BrewMath.formatSeconds(step.startSeconds))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.faint)
                                .frame(width: 42, alignment: .leading)
                            Text(step.instruction).font(.subheadline)
                            Spacer(minLength: 8)
                            if step.cumulativeWaterFraction != nil {
                                Text(BrewMath.formatGrams(targets[index]))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Theme.water)
                            }
                        }
                    }
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Start brew") { start() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
            .onAppear(perform: loadDefaults)
        }
    }

    /// The recipe as it will actually run, so the step list reflects the steep
    /// time rather than the authored default.
    private var effectiveRecipe: Recipe {
        method.param(.steepTime) == nil ? recipe : recipe.withSteepSeconds(steepTime)
    }

    private var targets: [Double] {
        BrewMath.cumulativeTargets(steps: effectiveRecipe.steps, totalWater: water)
    }

    private var doseRange: ClosedRange<Double> {
        guard let def = method.param(.dose) else { return 8...60 }
        return def.minimum...def.maximum
    }

    private var ratioRange: ClosedRange<Double> {
        guard let def = method.param(.ratio) else { return 13...20 }
        return def.minimum...def.maximum
    }

    private func loadDefaults() {
        guard !loaded else { return }
        loaded = true

        dose = recipe.dose
        ratio = recipe.ratio
        waterTemp = recipe.parameters.value(.waterTemp, default: 94)
        steepTime = recipe.parameters.value(.steepTime, default: 240)
        beanID = model.data.lastBeanID

        if let grinder {
            grinderSetting = grinder.setting(fromNormalised: recipe.parameters.value(.grind, default: 50))
        }

        // Yesterday's decision, already applied — the improvement happens without
        // the user having to remember anything.
        if let adjustment = pending?.adjustment {
            if let setting = adjustment.newGrinderSetting { grinderSetting = setting }
            apply(adjustment)
        }
    }

    /// Exhaustive on purpose. A new lever in the engine should fail to compile
    /// here rather than silently produce an adjustment the user can save and
    /// never see applied.
    private func apply(_ adjustment: Adjustment) {
        guard let key = adjustment.paramKey, let value = adjustment.newValue else { return }
        switch key {
        case .dose: dose = value
        case .ratio: ratio = value
        case .waterTemp: waterTemp = value
        case .steepTime: steepTime = value
        case .grind: break                       // applied via newGrinderSetting, in the user's own units
        case .bloomWater, .bloomTime, .yield, .pressure, .shotTime:
            break                                // not levers this screen offers yet
        }
    }

    private func start() {
        var params = recipe.parameters
        params[.dose] = dose
        params[.ratio] = ratio
        params[.waterTemp] = waterTemp
        if method.param(.steepTime) != nil { params[.steepTime] = steepTime }
        if let grinder { params[.grind] = grinder.normalised(fromSetting: grinderSetting) }

        let session = BrewSession(
            recipe: recipe,
            method: method,
            params: params,
            bean: model.bean(id: beanID),
            grinder: grinder,
            grinderSetting: grinder == nil ? nil : grinderSetting,
            adjustedFromBrewID: pending?.sourceBrewID,
            waterSource: model.data.waterSource
        )

        model.clearPendingAdjustment(forMethod: recipe.methodID)
        dismiss()
        flow.session = session
    }
}
