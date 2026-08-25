import Foundation
import CoffeeKit

/// Everything the app owns, in one Codable document.
///
/// Why a JSON document rather than SwiftData: a brew journal is small (a heavy
/// user makes maybe a thousand records a year), v1 has no sync, and export is a
/// hard requirement rather than a nice-to-have. A single Codable file gives us
/// atomic writes, a trivial export path, an easy pre-migration backup, and — the
/// deciding factor — it lives in the App Group where the widgets can already
/// read it, with no second process contending on a store.
///
/// SwiftData plus CloudKit is the right answer when sync arrives in v1.1. It is
/// not the right answer for shipping the loop.
struct AppData: Codable {
    var brews: [Brew] = []
    var beans: [Bean] = []
    var grinders: [Grinder] = []
    var selectedGrinderID: UUID?
    var userRecipes: [Recipe] = []
    /// Keyed by method — an adjustment is only meaningful for the brewer it came from.
    var pendingAdjustments: [String: PendingAdjustment] = [:]
    var lastRecipeID: String?
    var lastBeanID: UUID?
    var hasOnboarded: Bool = false
    var usesCelsius: Bool = true
    /// What the user brews with. Asked once; frozen onto each brew.
    var waterSource: WaterSource = .unknown
    /// Whether grind is a lever at all for this user. Decides what advice the
    /// engine is allowed to give.
    var buysPreGround: Bool = false
    /// The water explanation interrupts once, then gets out of the way.
    var hasSeenWaterAdvice: Bool = false
    /// Remembered per method so the milk question costs zero taps in the steady state.
    var milkDefaults: [String: Bool] = [:]

    static let empty = AppData()

    /// Documents written before water, pre-ground and milk existed decode with
    /// sensible defaults rather than failing. Swift's synthesised decoder ignores
    /// property defaults for missing keys, so every additive change needs this.
    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        brews = try c.decodeIfPresent([Brew].self, forKey: .brews) ?? []
        beans = try c.decodeIfPresent([Bean].self, forKey: .beans) ?? []
        grinders = try c.decodeIfPresent([Grinder].self, forKey: .grinders) ?? []
        selectedGrinderID = try c.decodeIfPresent(UUID.self, forKey: .selectedGrinderID)
        userRecipes = try c.decodeIfPresent([Recipe].self, forKey: .userRecipes) ?? []
        pendingAdjustments = try c.decodeIfPresent([String: PendingAdjustment].self, forKey: .pendingAdjustments) ?? [:]
        lastRecipeID = try c.decodeIfPresent(String.self, forKey: .lastRecipeID)
        lastBeanID = try c.decodeIfPresent(UUID.self, forKey: .lastBeanID)
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? false
        usesCelsius = try c.decodeIfPresent(Bool.self, forKey: .usesCelsius) ?? true
        waterSource = try c.decodeIfPresent(WaterSource.self, forKey: .waterSource) ?? .unknown
        buysPreGround = try c.decodeIfPresent(Bool.self, forKey: .buysPreGround) ?? false
        hasSeenWaterAdvice = try c.decodeIfPresent(Bool.self, forKey: .hasSeenWaterAdvice) ?? false
        milkDefaults = try c.decodeIfPresent([String: Bool].self, forKey: .milkDefaults) ?? [:]
    }
}

/// Reads and writes the document. Atomic, offline, and never on the critical
/// path of a brew.
struct AppDataStore {
    private let fileName = "grind-data.json"

    private var directory: URL {
        AppGroup.containerURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var fileURL: URL { directory.appendingPathComponent(fileName) }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        guard let decoded = try? makeDecoder().decode(AppData.self, from: data) else {
            // Keep the unreadable file rather than overwriting it — the journal is
            // the one thing in this app that cannot be regenerated.
            let backup = fileURL.deletingPathExtension().appendingPathExtension("corrupt.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: fileURL, to: backup)
            return .empty
        }
        return decoded
    }

    func save(_ data: AppData) {
        guard let encoded = try? makeEncoder().encode(data) else { return }
        // Same defensiveness as SharedStore: the App Group container is created by
        // the system, but the fallback directory may not exist yet.
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? encoded.write(to: fileURL, options: .atomic)
    }

    /// Offline, unrestricted, and never behind the paywall. Users trust a journal
    /// they can get out.
    func exportJSON(_ data: AppData) -> Data? {
        try? makeEncoder().encode(data)
    }

    func exportCSV(_ data: AppData) -> String {
        var rows = ["date,method,recipe,bean,rest_days,dose_g,ratio,water_g,grind_setting,water_temp_c,total_seconds,rating,extraction,strength,descriptors,rule,adjustment,note"]
        let formatter = ISO8601DateFormatter()

        for brew in data.brews.sorted(by: { $0.startedAt < $1.startedAt }) {
            let bean = data.beans.first { $0.id == brew.beanID }
            let recipe = (BuiltInContent.recipe(id: brew.recipeID ?? "")
                          ?? data.userRecipes.first { $0.id == brew.recipeID })
            let fields: [String] = [
                formatter.string(from: brew.startedAt),
                brew.methodID,
                recipe?.name ?? "",
                bean?.name ?? "",
                brew.beanRestDays.map(String.init) ?? "",
                String(format: "%.1f", brew.dose),
                String(format: "%.1f", brew.ratio),
                String(format: "%.0f", brew.totalWater),
                brew.grinderSetting.map { String(format: "%.1f", $0) } ?? "",
                brew.params[.waterTemp].map { String(format: "%.0f", $0) } ?? "",
                brew.actualTotalSeconds.map(String.init) ?? "",
                brew.taste.map { String($0.rating) } ?? "",
                brew.taste.map { String($0.extraction) } ?? "",
                brew.taste.map { String($0.strength) } ?? "",
                brew.taste?.descriptors.map(\.rawValue).joined(separator: " ") ?? "",
                brew.diagnosis.map { String($0.ruleID) } ?? "",
                brew.diagnosis?.adjustment.headline ?? "",
                brew.note ?? ""
            ]
            rows.append(fields.map(Self.escapeCSV).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escapeCSV(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
