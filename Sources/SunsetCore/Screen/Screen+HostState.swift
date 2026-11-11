extension Screen {
    mutating func takeEvents() -> [HostEvent] {
        let taken = host.events
        host.events.removeAll(keepingCapacity: true)
        return taken
    }

    /// Where a stable line (see `PromptMark`) is now, counted from the oldest line of the history; nil when it was dropped from the history.
    public func absoluteLine(ofStable stable: Int) -> Int? {
        let line = stable - scrollback.evicted
        return line >= 0 && line < absoluteLineCount ? line : nil
    }

    /// The line of the nearest prompt above (`previous`) or below (`next`) `line`, both counted from the oldest line of the history; nil when there is
    /// none that way (below the last prompt is the live screen). Only where a prompt starts counts, and only while its line is still in the history.
    public func promptLine(_ direction: PromptMark.Direction, from line: Int) -> Int? {
        var found: Int?
        for mark in host.marks where mark.kind == .promptStart {
            guard let prompt = absoluteLine(ofStable: mark.stableLine) else { continue }
            switch direction {
                case .previous: if prompt < line, prompt > found ?? -1 { found = prompt }
                case .next: if prompt > line, prompt < found ?? Int.max { found = prompt }
            }
        }
        return found
    }

    /// The stable number of the line the cursor is on.
    var cursorStableLine: Int { scrollback.evicted + scrollback.count + row }
}
