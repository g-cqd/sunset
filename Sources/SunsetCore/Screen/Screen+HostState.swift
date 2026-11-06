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

    /// The stable number of the line the cursor is on.
    var cursorStableLine: Int { scrollback.evicted + scrollback.count + row }
}
