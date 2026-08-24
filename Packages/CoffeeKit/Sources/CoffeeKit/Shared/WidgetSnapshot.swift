import Foundation

/// The App Group identifier the app and the widget extension share.
///
/// This is the single string that has to match in three places — both
/// entitlements files and here. `project.yml` generates all three from one
/// setting so they can't drift.
///
/// - Note: App Groups need a paid Apple Developer account on device. In the
///   Simulator the container is created without one, so `SharedStore` also
///   falls back to a local file — widgets still work in Simulator previews.
public enum AppGroup {
    public static let identifier = "group.com.haxsh.grind"

    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

// MARK: - Widget-sized projections

/// Widgets get their own small, flat projections rather than the full model
/// objects. A widget process is memory-constrained and reloads often; decoding a
/// whole journal to render "brew again" would be wasteful and fragile.
public struct BrewSummary: Codable, Hashable, Sendable {
    public var brewID: UUID
    public var methodID: String
    public var methodName: String
    public var recipeID: String?
    public var recipeName: String
    public var beanName: String?
    public var rating: Int?
    public var brewedAt: Date

    public init(
        brewID: UUID,
        methodID: String,
        methodName: String,
        recipeID: String? = nil,
        recipeName: String,
        beanName: String? = nil,
        rating: Int? = nil,
        brewedAt: Date
    ) {
        self.brewID = brewID
        self.methodID = methodID
        self.methodName = methodName
        self.recipeID = recipeID
        self.recipeName = recipeName
        self.beanName = beanName
        self.rating = rating
        self.brewedAt = brewedAt
    }
}

public struct AdjustmentSummary: Codable, Hashable, Sendable {
    public var headline: String
    public var detail: String
    public var kind: Adjustment.Kind

    public init(headline: String, detail: String, kind: Adjustment.Kind) {
        self.headline = headline
        self.detail = detail
        self.kind = kind
    }

    public init(_ adjustment: Adjustment) {
        self.headline = adjustment.headline
        self.detail = adjustment.detail
        self.kind = adjustment.kind
    }
}

public struct BeanSummary: Codable, Hashable, Sendable {
    public var beanID: UUID
    public var name: String
    public var roaster: String?
    public var restDays: Int?
    public var freshness: Freshness?
    public var roastLevel: RoastLevel

    public init(
        beanID: UUID,
        name: String,
        roaster: String? = nil,
        restDays: Int? = nil,
        freshness: Freshness? = nil,
        roastLevel: RoastLevel = .light
    ) {
        self.beanID = beanID
        self.name = name
        self.roaster = roaster
        self.restDays = restDays
        self.freshness = freshness
        self.roastLevel = roastLevel
    }

    public init(bean: Bean, asOf now: Date = Date()) {
        self.beanID = bean.id
        self.name = bean.name
        self.roaster = bean.roaster
        self.restDays = bean.restDays(asOf: now)
        self.freshness = bean.freshness(asOf: now)
        self.roastLevel = bean.roastLevel
    }
}

/// Everything the widgets need, in one small file.
public struct WidgetSnapshot: Codable, Hashable, Sendable {
    public var lastBrew: BrewSummary?
    public var pendingAdjustment: AdjustmentSummary?
    public var activeBean: BeanSummary?
    public var totalBrews: Int
    public var updatedAt: Date

    public init(
        lastBrew: BrewSummary? = nil,
        pendingAdjustment: AdjustmentSummary? = nil,
        activeBean: BeanSummary? = nil,
        totalBrews: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.lastBrew = lastBrew
        self.pendingAdjustment = pendingAdjustment
        self.activeBean = activeBean
        self.totalBrews = totalBrews
        self.updatedAt = updatedAt
    }

    public var hasBrewed: Bool { lastBrew != nil }

    /// Shown in widget galleries and in Xcode previews, where there is no real
    /// data. Deliberately plausible rather than empty — a gallery entry that
    /// looks broken doesn't get added.
    public static let placeholder = WidgetSnapshot(
        lastBrew: BrewSummary(
            brewID: UUID(),
            methodID: "v60",
            methodName: "V60",
            recipeID: "v60-everyday",
            recipeName: "Everyday V60",
            beanName: "Ethiopia Guji",
            rating: 3,
            brewedAt: Date(timeIntervalSinceNow: -86_400)
        ),
        pendingAdjustment: AdjustmentSummary(
            headline: "Grind finer",
            detail: "18 → 16 clicks",
            kind: .grindFiner
        ),
        activeBean: BeanSummary(
            beanID: UUID(),
            name: "Ethiopia Guji",
            roaster: "Assembly",
            restDays: 9,
            freshness: .peak,
            roastLevel: .light
        ),
        totalBrews: 24,
        updatedAt: Date()
    )

    /// What a user who has installed the app but not brewed yet should see.
    public static let empty = WidgetSnapshot()
}
