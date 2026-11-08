/// A part of the configuration that a new file changed: what the app has to apply to a running terminal.
public enum ConfigurationChange: Sendable, Equatable {
    case font, colors, window, sidebar, appearance, tabs, layout, terminal, theme, scroll, keyboard, scrollback,
        cursorBlink, cursorStyle,
        renderer
}

extension Configuration {
    /// The parts of `self` that differ from `old`, each once, in a fixed order.
    public func changes(from old: Configuration) -> [ConfigurationChange] {
        let differences: [(ConfigurationChange, Bool)] = [
            (.font, font != old.font), (.colors, colors != old.colors), (.window, window != old.window),
            (.sidebar, sidebar != old.sidebar), (.appearance, appearance != old.appearance), (.tabs, tabs != old.tabs),
            (.layout, layout != old.layout), (.terminal, terminal != old.terminal),
            (.theme, theme != old.theme), (.scroll, scroll != old.scroll), (.keyboard, keyboard != old.keyboard),
            (.scrollback, scrollbackLines != old.scrollbackLines),
            (.cursorBlink, cursorBlinkTimeout != old.cursorBlinkTimeout),
            (.cursorStyle, (cursorShape, cursorBlinks) != (old.cursorShape, old.cursorBlinks)),
            (.renderer, renderer != old.renderer)
        ]
        return differences.filter(\.1).map(\.0)
    }
}
