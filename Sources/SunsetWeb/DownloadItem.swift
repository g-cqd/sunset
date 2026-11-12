package import Foundation
package import Observation
import WebKit

/// One download (web step f): where it comes from, where it goes, how far it is, and what resumes it once stopped or cut.
@MainActor @Observable
package final class DownloadItem: Identifiable {
    package enum State: String, Codable, Sendable {
        case running, paused, finished, failed
    }

    package let id: UUID
    package let source: URL?
    package let origin: URL?
    package internal(set) var name: String
    /// Where the finished file is (the partial one is beside it, ending in .download).
    package internal(set) var destination: URL?
    package internal(set) var received: Int64 = 0
    package internal(set) var expected: Int64?
    package internal(set) var state = State.running
    package internal(set) var started: Date
    package internal(set) var finished: Date?
    package internal(set) var failure: String?
    @ObservationIgnored var resumeData: Data?
    @ObservationIgnored weak var download: WKDownload?
    @ObservationIgnored var observation: NSKeyValueObservation?

    init(id: UUID = UUID(), source: URL?, origin: URL?, name: String, started: Date = Date()) {
        self.id = id
        self.source = source
        self.origin = origin
        self.name = name
        self.started = started
    }

    /// From 0 to 1 when the size is known.
    package var fraction: Double? {
        guard let expected, expected > 0 else { return nil }
        return min(Double(received) / Double(expected), 1)
    }

    package var canResume: Bool { state == .paused && resumeData != nil }

    var partial: URL? {
        destination.map { $0.deletingLastPathComponent().appending(path: DownloadNaming.partial($0.lastPathComponent)) }
    }

    // MARK: Saving

    struct Record: Codable {
        var id: UUID
        var source: URL?
        var origin: URL?
        var name: String
        var destination: URL?
        var received: Int64
        var expected: Int64?
        var state: State
        var started: Date
        var finished: Date?
        var resumeData: Data?
    }

    var record: Record {
        Record(
            id: id,
            source: source,
            origin: origin,
            name: name,
            destination: destination,
            received: received,
            expected: expected,
            state: state,
            started: started,
            finished: finished,
            resumeData: resumeData
        )
    }

    /// A saved download; one that was running when the app ended is paused (resumed by hand, from its saved data).
    convenience init(_ record: Record) {
        self.init(
            id: record.id,
            source: record.source,
            origin: record.origin,
            name: record.name,
            started: record.started
        )
        destination = record.destination
        received = record.received
        expected = record.expected
        state = record.state == .running ? (record.resumeData == nil ? .failed : .paused) : record.state
        finished = record.finished
        resumeData = record.resumeData
    }
}
