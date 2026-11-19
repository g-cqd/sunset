extension Favorites.Entry {
    /// The kinds of pane it starts from, each once, in the order of its panes; a pane with nothing said is a terminal.
    public var kinds: [String] {
        var kinds: [String] = []
        for pane in home.layout.panes {
            let kind = home.contents[pane]?.kind ?? PaneDescriptor.terminalKind
            if !kinds.contains(kind) { kinds.append(kind) }
        }
        return kinds
    }

    /// Whether one of its panes is of `kind`: what it starts from, or what it holds now.
    public func has(kind: String) -> Bool {
        kinds.contains(kind)
    }
}
