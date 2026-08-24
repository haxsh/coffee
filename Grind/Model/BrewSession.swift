import Foundation
import Observation
import ActivityKit
import AVFoundation
import UIKit
import CoffeeKit

/// Drives one brew from first pour to the log screen.
///
/// The design context is a counter, not a desk: wet hands, steam, a kettle in one
/// hand, and roughly ninety seconds of divided attention. Three things follow
/// from that and they shape everything here.
///
/// - The user must be able to run a brew **without looking**, so every step
///   change fires an audio cue and a haptic.
/// - The brew must **survive the phone locking**, an incoming call, or the user
///   checking a message, so the source of truth is a Live Activity whose clock
///   the system renders from a date rather than from anything we have to keep
///   awake.
/// - Nothing may **block on the network**, so there is none.
@Observable
@MainActor
final class BrewSession {

    // MARK: - Fixed for the brew

    let recipe: Recipe
    let method: BrewMethod
    let params: BrewParameters
    let beanID: UUID?
    let beanRestDays: Int?
    let beanFreshness: Freshness?
    let beanName: String?
    let grinderID: UUID?
    let grinderSetting: Double?
    let adjustedFromBrewID: UUID?
    let plannedParams: BrewParameters

    let totalWater: Double
    let cumulativeTargets: [Double]

    // MARK: - Live state

    private(set) var elapsed: TimeInterval = 0
    private(set) var stepIndex: Int = 0
    private(set) var isPaused = false
    private(set) var isComplete = false
    private(set) var startedAt = Date()

    private var effectiveStart = Date()
    private var frozenElapsed: TimeInterval = 0
    private var ticker: Timer?
    private var lastTickSecond: Int = -1
    private var activity: Activity<BrewActivityAttributes>?
    private var players: [AudioCue: AVAudioPlayer] = [:]

    // MARK: - Init

    init(
        recipe: Recipe,
        method: BrewMethod,
        params: BrewParameters,
        bean: Bean? = nil,
        grinder: Grinder? = nil,
        grinderSetting: Double? = nil,
        adjustedFromBrewID: UUID? = nil
    ) {
        self.recipe = recipe
        self.method = method
        self.params = params
        self.plannedParams = recipe.parameters
        self.beanID = bean?.id
        self.beanName = bean?.name
        self.beanRestDays = bean?.restDays()
        self.beanFreshness = bean?.freshness()
        self.grinderID = grinder?.id
        self.grinderSetting = grinderSetting
        self.adjustedFromBrewID = adjustedFromBrewID

        let water = BrewMath.water(
            dose: params.value(.dose, default: recipe.dose),
            ratio: params.value(.ratio, default: recipe.ratio)
        )
        self.totalWater = water
        self.cumulativeTargets = BrewMath.cumulativeTargets(steps: recipe.steps, totalWater: water)
    }

    // MARK: - Reading the current state

    var steps: [RecipeStep] { recipe.steps }
    var stepCount: Int { steps.count }

    var currentStep: RecipeStep? {
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    var nextStep: RecipeStep? {
        let next = stepIndex + 1
        guard steps.indices.contains(next) else { return nil }
        return steps[next]
    }

    var currentTarget: Double {
        guard cumulativeTargets.indices.contains(stepIndex) else { return totalWater }
        return cumulativeTargets[stepIndex]
    }

    /// Seconds remaining in the current step, or nil once the brew has run past
    /// its plan. Overrunning is allowed and is not an error state.
    var secondsRemainingInStep: Int? {
        guard let step = currentStep else { return nil }
        let remaining = Double(step.endSeconds) - elapsed
        return remaining >= 0 ? Int(remaining.rounded(.up)) : nil
    }

    var isOverrunning: Bool {
        guard let step = currentStep else { return false }
        return elapsed > Double(step.endSeconds) + 1 && stepIndex == stepCount - 1
    }

    var stepProgress: Double {
        guard let step = currentStep, step.durationSeconds > 0 else { return 0 }
        let into = elapsed - Double(step.startSeconds)
        return min(1, max(0, into / Double(step.durationSeconds)))
    }

    var waterProgress: Double {
        guard totalWater > 0 else { return 0 }
        return min(1, currentTarget / totalWater)
    }

    // MARK: - Controls

    func start() {
        startedAt = Date()
        effectiveStart = Date()
        elapsed = 0
        stepIndex = 0
        isPaused = false
        isComplete = false

        prepareAudio()
        UIApplication.shared.isIdleTimerDisabled = true   // the screen must not sleep mid-pour
        startTicker()
        startLiveActivity()
        AudioCue.step.play(from: players)
        Haptics.stepChange()
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func pause() {
        guard !isPaused, !isComplete else { return }
        frozenElapsed = elapsed
        isPaused = true
        ticker?.invalidate()
        ticker = nil
        updateLiveActivity()
    }

    func resume() {
        guard isPaused, !isComplete else { return }
        effectiveStart = Date().addingTimeInterval(-frozenElapsed)
        isPaused = false
        startTicker()
        updateLiveActivity()
    }

    /// Skip ahead when a step is finished early — a pour that went faster than
    /// planned shouldn't leave the user standing there waiting for the clock.
    func advance() {
        guard !isComplete else { return }
        guard let next = nextStep else { return finish() }
        jump(to: TimeInterval(next.startSeconds))
        setStepIndex(stepIndex + 1, announce: true)
    }

    /// Deliberately generous: a user reaching for +15s is already behind and
    /// should not have to tap four times.
    func addTime(_ seconds: TimeInterval = 15) {
        jump(to: max(0, elapsed - seconds))
    }

    func finish() {
        guard !isComplete else { return }
        isComplete = true
        ticker?.invalidate()
        ticker = nil
        UIApplication.shared.isIdleTimerDisabled = false
        AudioCue.done.play(from: players)
        Haptics.brewComplete()
        endLiveActivity()
        deactivateAudio()
    }

    /// Abandon without logging. Used by the close button, after confirmation.
    func cancel() {
        ticker?.invalidate()
        ticker = nil
        isComplete = true
        UIApplication.shared.isIdleTimerDisabled = false
        endLiveActivity()
        deactivateAudio()
    }

    /// The record this brew becomes. Everything downstream — diagnosis, journal,
    /// widgets — reads from here.
    func makeBrew() -> Brew {
        Brew(
            startedAt: startedAt,
            methodID: method.id,
            recipeID: recipe.id,
            beanID: beanID,
            params: params,
            plannedParams: plannedParams,
            grinderID: grinderID,
            grinderSetting: grinderSetting,
            beanRestDays: beanRestDays,
            beanFreshness: beanFreshness,
            actualTotalSeconds: Int(elapsed.rounded()),
            adjustedFromBrewID: adjustedFromBrewID
        )
    }

    // MARK: - Ticking

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // .common so the clock keeps running while the user scrolls or drags a sheet.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        guard !isPaused, !isComplete else { return }
        elapsed = Date().timeIntervalSince(effectiveStart)

        // Countdown ticks in the last three seconds, once per second, so the user
        // can feel a step ending without watching for it.
        if let remaining = secondsRemainingInStep, remaining <= 3, remaining > 0 {
            if lastTickSecond != remaining {
                lastTickSecond = remaining
                AudioCue.tick.play(from: players)
                Haptics.countdown()
            }
        }

        // Auto-advance: the clock is the truth, not a button the user has to
        // remember to press with wet hands.
        if let step = currentStep, elapsed >= Double(step.endSeconds) {
            if stepIndex + 1 < stepCount {
                setStepIndex(stepIndex + 1, announce: true)
            } else {
                finish()
            }
        }
    }

    private func jump(to newElapsed: TimeInterval) {
        effectiveStart = Date().addingTimeInterval(-newElapsed)
        frozenElapsed = newElapsed
        elapsed = newElapsed
        if isPaused { updateLiveActivity() }
    }

    private func setStepIndex(_ index: Int, announce: Bool) {
        guard steps.indices.contains(index) else { return }
        stepIndex = index
        lastTickSecond = -1
        if announce {
            AudioCue.step.play(from: players)
            Haptics.stepChange()
            announceForVoiceOver()
        }
        updateLiveActivity()
    }

    /// VoiceOver users are the clearest case of "running the brew without
    /// looking", so step changes are announced at assertive priority.
    private func announceForVoiceOver() {
        guard let step = currentStep, UIAccessibility.isVoiceOverRunning else { return }
        let target = BrewMath.formatGrams(currentTarget)
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(step.instruction) Target \(target)."
        )
    }

    // MARK: - Live Activity

    private var activityState: BrewActivityAttributes.ContentState {
        BrewActivityAttributes.ContentState(
            stepIndex: stepIndex,
            stepCount: stepCount,
            stepKind: currentStep?.kind.rawValue ?? "drawdown",
            instruction: currentStep?.instruction ?? "Let it draw down.",
            cumulativeTargetGrams: currentTarget,
            totalWaterGrams: totalWater,
            effectiveStartDate: effectiveStart,
            isPaused: isPaused,
            pausedElapsed: frozenElapsed,
            isComplete: isComplete
        )
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = BrewActivityAttributes(
            recipeName: recipe.name,
            methodName: method.name,
            beanName: beanName
        )
        let content = ActivityContent(
            state: activityState,
            staleDate: Date().addingTimeInterval(TimeInterval(recipe.totalSeconds + 300))
        )
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    private func updateLiveActivity() {
        guard let activity else { return }
        let content = ActivityContent(
            state: activityState,
            staleDate: Date().addingTimeInterval(TimeInterval(recipe.totalSeconds + 300))
        )
        Task { await activity.update(content) }
    }

    private func endLiveActivity() {
        guard let activity else { return }
        let content = ActivityContent(state: activityState, staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(20))) }
        self.activity = nil
    }

    // MARK: - Audio

    /// `.playback` with `.duckOthers` is the whole trick: cues are audible even
    /// with the ring switch off — which is where phones live in kitchens — and a
    /// podcast ducks under them rather than stopping.
    private func prepareAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
        for cue in AudioCue.allCases {
            guard let url = Bundle.main.url(forResource: cue.fileName, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            player.volume = cue.volume
            players[cue] = player
        }
    }

    private func deactivateAudio() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

// MARK: - Cues

enum AudioCue: String, CaseIterable {
    case step, tick, done

    var fileName: String {
        switch self {
        case .step: return "cue-step"
        case .tick: return "cue-tick"
        case .done: return "cue-done"
        }
    }

    var volume: Float {
        switch self {
        case .step: return 1.0
        case .tick: return 0.5
        case .done: return 1.0
        }
    }

    func play(from players: [AudioCue: AVAudioPlayer]) {
        guard let player = players[self] else { return }
        player.currentTime = 0
        player.play()
    }
}

/// Haptics are reserved for syncing the user to the physical world — step
/// changes, countdowns, the end of a brew. Never for navigation: overusing the
/// channel burns exactly the sense the guided brew depends on.
enum Haptics {
    @MainActor
    static func stepChange() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    @MainActor
    static func countdown() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor
    static func brewComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
