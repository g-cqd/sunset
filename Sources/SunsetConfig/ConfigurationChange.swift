/// A part of the configuration that a new file changed: what the app has to apply to a running terminal.
public enum ConfigurationChange: Sendable, Equatable {
    case font, colors, window, scrollback, cursorBlink, renderer
}

extension Configuration {
    /// The parts of `self` that differ from `old`, each once, in a fixed order.
    public func changes(from old: Configuration) -> [ConfigurationChange] {
        var changes: [ConfigurationChange] = []
        if font != old.font { changes.append(.font) }
        if colors != old.colors { changes.append(.colors) }
        if window != old.window { changes.append(.window) }
        if scrollbackLines != old.scrollbackLines { changes.append(.scrollback) }
        if cursorBlinkTimeout != old.cursorBlinkTimeout { changes.append(.cursorBlink) }
        if renderer != old.renderer { changes.append(.renderer) }
        return changes
    }
}
