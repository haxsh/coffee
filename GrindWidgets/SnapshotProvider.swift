import WidgetKit
import CoffeeKit

/// Widgets read the small JSON projection the app writes to the shared App Group
/// container — never the app's own document.
///
/// The refresh policy is `.never` on purpose: the app calls
/// `WidgetCenter.reloadAllTimelines()` on every mutation, so the widget is pushed
/// rather than polled. Asking WidgetKit to wake us on a schedule would burn
/// budget re-rendering data that hasn't changed, and still lag a brew that just
/// finished.
struct SnapshotProvider: TimelineProvider {

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .placeholder)
    }

    /// The widget gallery. Deliberately populated rather than empty — a gallery
    /// entry that looks broken doesn't get added to a home screen.
    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.placeholder : SharedStore.shared.load()
        completion(SnapshotEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), snapshot: SharedStore.shared.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}
