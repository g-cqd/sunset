public import Foundation
public import Observation
public import SunsetRuntime
public import SunsetStorage

/// The files opened lately (roadmap 0031; the owner, 2026-11-16: listed with the documents in the Library): the last twenty,
/// each once, the latest first. Kept in the state database, each record sealed and named there by a keyed hash, so that the
/// names of the person's files are not written in plain. Nothing of a file is read to list it: a file that is gone is still
/// listed, and says so when opened.
@MainActor @Observable
public final class RecentFiles {
    public struct Entry: Equatable, Sendable, Identifiable {
        public let path: String
        public let opened: Date

        public var id: String {
            path
        }
    }

    private struct Kept: Codable {
        var path: String
        var opened: Double
    }

    public static let limit = 20

    /// The latest first.
    public private(set) var entries: [Entry] = []
    @ObservationIgnored private let table: SealedTable?

    /// - Parameter table: where they are kept; nil when nothing can be kept in this run, and they last as long as it does.
    public init(table: SealedTable?) {
        self.table = table
        guard let table else { return }
        let decoder = JSONDecoder()
        entries = table.all().rows
            .compactMap { row in
                (try? decoder.decode(Kept.self, from: row.payload))
                    .map {
                        Entry(path: $0.path, opened: Date(timeIntervalSince1970: $0.opened))
                    }
            }
            .sorted { $0.opened > $1.opened }
    }

    /// `path` was opened at `date`: it is the first, and what is past the twentieth is forgotten.
    public func note(_ path: String, at date: Date = Runtime.live.now()) {
        entries.removeAll { $0.path == path }
        entries.insert(Entry(path: path, opened: date), at: 0)
        let kept = Kept(path: path, opened: date.timeIntervalSince1970)
        if let payload = try? JSONEncoder().encode(kept) {
            table?.put(path, payload: payload, sort: date.timeIntervalSince1970)
        }
        while entries.count > Self.limit {
            // Taken off first: with no table, an argument of a call on it would never be read (and the loop never end).
            let forgotten = entries.removeLast()
            table?.remove(forgotten.path)
        }
    }

    public func remove(_ path: String) {
        entries.removeAll { $0.path == path }
        table?.remove(path)
    }

    public func clear() {
        entries = []
        table?.removeAll()
    }
}
