/// What the OSC sequences that reach outside the screen leave behind (ADR-0010): a bounded queue of events for the host, and the latest state of the
/// working directory, progress and prompt marks.
struct HostState: Sendable {
    static let eventLimit = 64
    static let markLimit = 4096

    var events: [HostEvent] = []
    var workingDirectory: WorkingDirectory?
    var progress = ProgressState.hidden
    var marks: [PromptMark] = []
    /// A notification being assembled over several OSC 99 sequences, by its id.
    var pendingNotification: (id: String, title: String, body: String)?

    mutating func post(_ event: HostEvent) {
        if events.count == Self.eventLimit { events.removeFirst() }
        events.append(event)
    }

    mutating func addMark(_ mark: PromptMark) {
        if marks.count == Self.markLimit { marks.removeFirst() }
        marks.append(mark)
    }
}
