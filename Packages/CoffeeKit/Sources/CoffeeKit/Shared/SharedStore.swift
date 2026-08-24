import Foundation

/// Moves the widget snapshot between the app and the widget extension.
///
/// The app's own source of truth is SwiftData; this writes a tiny JSON
/// projection of it into the shared App Group container on every change. Widgets
/// only ever read that file.
///
/// Doing it this way rather than pointing the widget at SwiftData directly keeps
/// the widget process out of schema migrations and store contention — a widget
/// that crashes because the app is mid-migration shows as a blank tile on the
/// home screen, which users read as a broken app.
public struct SharedStore: Sendable {
    public static let shared = SharedStore()

    private let fileName = "widget-snapshot.json"

    public init() {}

    /// The App Group container when it exists, otherwise Caches.
    ///
    /// The fallback matters: App Groups require a paid developer account on
    /// device, and unit tests have no container at all. Falling back keeps the
    /// app working — the widget just won't see updates.
    private var directory: URL {
        if let container = AppGroup.containerURL { return container }
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private var fileURL: URL {
        directory.appendingPathComponent(fileName)
    }

    public func load() -> WidgetSnapshot {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data) else {
            // A snapshot we can't read is a snapshot we should replace, not crash on.
            return .empty
        }
        return snapshot
    }

    @discardableResult
    public func save(_ snapshot: WidgetSnapshot) -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
