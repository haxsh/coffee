import Foundation

/// Moves the widget snapshot between the app and the widget extension.
///
/// The app's own source of truth is its document; this writes a tiny JSON
/// projection of it into the shared App Group container on every change. Widgets
/// only ever read that file.
///
/// Doing it this way rather than pointing the widget at the app's store keeps the
/// widget process out of schema migrations and file contention — a widget that
/// fails because the app is mid-write shows as a blank tile on the home screen,
/// which users read as a broken app.
public struct SharedStore: Sendable {

    /// What the app and the widget extension both use.
    public static let shared = SharedStore()

    private static let fileName = "widget-snapshot.json"

    public let directory: URL

    /// - Parameter directory: overrides where the snapshot lives. Tests pass their
    ///   own temporary directory; production leaves this nil and gets the App
    ///   Group container.
    public init(directory: URL? = nil) {
        self.directory = directory
            ?? AppGroup.containerURL
            // App Groups need a paid developer account on device and don't exist
            // at all outside an app process. Falling back keeps the app working —
            // the widget just won't see updates.
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }

    public var fileURL: URL {
        directory.appendingPathComponent(Self.fileName)
    }

    public func load() -> WidgetSnapshot {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // A snapshot we can't read is one to replace, not crash on.
        return (try? decoder.decode(WidgetSnapshot.self, from: data)) ?? .empty
    }

    /// Throwing variant. Used by tests so a filesystem failure reports *why*
    /// rather than surfacing as a bare false.
    public func write(_ snapshot: WidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)

        // The App Group container is created by the system, but a fallback
        // directory may not exist yet.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Call sites on the app's hot path can't do anything useful with a failure —
    /// a stale widget is not worth interrupting a brew for.
    @discardableResult
    public func save(_ snapshot: WidgetSnapshot) -> Bool {
        do {
            try write(snapshot)
            return true
        } catch {
            return false
        }
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
