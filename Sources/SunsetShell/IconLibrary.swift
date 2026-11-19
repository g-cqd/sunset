/// The icon picker's catalogs, read once and kept while a picker may want them (the owner, 2026-11-17: the picker was slow
/// "at loading all symbols"). They were read at each opening, with a spinner meanwhile; kept, a picker that opens has its
/// grid at once. They are dropped a while after the last picker closed: what they weigh is measured in the diary.
@MainActor
package final class IconLibrary {
    package static let shared = IconLibrary(idle: .seconds(120)) { IconCatalogs.load() }

    /// The catalogs, while they are kept.
    package private(set) var ready: IconCatalogs?
    private var reading: Task<IconCatalogs, Never>?
    private var dropping: Task<Void, Never>?
    private var pickers = 0
    private let idle: Duration
    private let read: @Sendable () -> IconCatalogs

    /// - Parameters:
    ///   - idle: how long the catalogs are kept after the last picker closed.
    ///   - read: reads them from the system's files; off the main actor, once while they are kept.
    package init(idle: Duration, read: @escaping @Sendable () -> IconCatalogs) {
        self.idle = idle
        self.read = read
    }

    /// The catalogs: read off the main actor when they are not kept, the same for everyone who asks meanwhile.
    package func catalogs() async -> IconCatalogs {
        if let ready { return ready }
        let task = reading ?? Task { [read] in await Self.reading(read) }
        reading = task
        let catalogs = await task.value
        ready = catalogs
        reading = nil
        return catalogs
    }

    @concurrent
    private static func reading(_ read: @Sendable () -> IconCatalogs) async -> IconCatalogs {
        read()
    }

    /// A picker opened: the catalogs stay.
    package func opened() {
        pickers += 1
        dropping?.cancel()
        dropping = nil
    }

    /// A picker closed: with none left, the catalogs are dropped once `idle` has passed with none opened.
    package func closed() {
        pickers = max(pickers - 1, 0)
        guard pickers == 0 else { return }
        dropping?.cancel()
        dropping = Task { [idle] in
            try? await Task.sleep(for: idle)
            guard !Task.isCancelled, pickers == 0 else { return }
            ready = nil
        }
    }
}
