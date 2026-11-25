package import Observation
package import SunsetCore
package import SunsetRender

/// Interactive scrollback & live-screen search state for one terminal (T-3 / roadmap 0026):
/// holds the query (`text`, `isRegex`, `matchCase`), the chronological match list, the currently focused match index,
/// and any regex compilation error. Drives `FrameView.search` highlights and jumps `Viewport` so the current match is
/// centered comfortably in view.
@MainActor @Observable
package final class TerminalFind {
    package var isOpen = false
    package var text = ""
    package var isRegex = false
    package var matchCase = false
    package private(set) var matches: [SearchMatch] = []
    package private(set) var index: Int?
    package private(set) var truncated = false
    package private(set) var error: String?
    /// Raised to put the keyboard in the find field.
    package private(set) var focusRequest = 0

    @ObservationIgnored package var onChanged: () -> Void = {}
    @ObservationIgnored package var onJumpToLine: (Int) -> Void = { _ in }
    @ObservationIgnored package var onClose: () -> Void = {}
    @ObservationIgnored package var currentScreen: () -> Screen? = { nil }
    @ObservationIgnored package var currentViewportFirstLine: () -> Int = { 0 }
    @ObservationIgnored package var currentViewportRows: () -> Int = { 24 }

    package init() {}

    /// The `SearchHighlight` handed to `FrameView` while the find bar is open.
    package var highlight: SearchHighlight {
        guard isOpen, !matches.isEmpty else { return SearchHighlight() }
        return SearchHighlight(matches: matches, current: index)
    }

    /// "3 of 12", "3 of 50000+", "Invalid regex", "Not found", or nothing.
    package var status: String {
        guard !text.isEmpty else { return "" }
        if error != nil { return "Invalid regex" }
        guard !matches.isEmpty else { return "Not found" }
        let suffix = truncated ? "+" : ""
        return index.map { "\($0 + 1) of \(matches.count)\(suffix)" } ?? "\(matches.count)\(suffix)"
    }

    /// Cmd-F: opens the find bar (or focuses it again) and refreshes matches against the latest screen.
    package func open() {
        isOpen = true
        focusRequest += 1
        if !text.isEmpty { restart() }
    }

    /// Cmd-E: seeds the query from the terminal's current text selection (switching off regex mode so literal text
    /// matches as selected).
    package func useSelection(_ selected: String?) {
        guard let selected, !selected.isEmpty else { return }
        isRegex = false
        text = selected
        isOpen = true
        restart()
    }

    /// Re-runs the query on the current screen, anchoring near the visible viewport (or keeping the nearest match).
    package func restart() {
        guard !text.isEmpty else {
            clearMatches()
            onChanged()
            return
        }
        guard let screen = currentScreen() else {
            clearMatches()
            onChanged()
            return
        }
        let result = screen.search(SearchQuery(text: text, isRegex: isRegex, matchCase: matchCase))
        matches = result.matches
        truncated = result.truncated
        error = result.error
        if matches.isEmpty {
            index = nil
        } else {
            // Pick the last match at or above the bottom of the current viewport (natural for terminals where newest
            // output is at the bottom), else the first match below.
            let bottomLine = currentViewportFirstLine() + max(currentViewportRows(), 1) - 1
            if let lastVisible = matches.lastIndex(where: { $0.start.line <= bottomLine }) {
                index = lastVisible
            } else {
                index = 0
            }
            jumpToCurrent()
        }
        onChanged()
    }

    /// Steps to the next (or previous) match, wrapping around the scrollback ends.
    package func step(backwards: Bool = false) {
        if matches.isEmpty, !text.isEmpty {
            restart()
            return
        }
        guard !matches.isEmpty else { return }
        if let current = index {
            index = backwards ? (current - 1 + matches.count) % matches.count : (current + 1) % matches.count
        } else {
            index = backwards ? matches.count - 1 : 0
        }
        jumpToCurrent()
        onChanged()
    }

    /// Closes the find bar and clears all highlights.
    package func close() {
        isOpen = false
        clearMatches()
        onChanged()
        onClose()
    }

    private func clearMatches() {
        matches = []
        index = nil
        truncated = false
        error = nil
    }

    private func jumpToCurrent() {
        guard let index, index < matches.count else { return }
        onJumpToLine(matches[index].start.line)
    }
}
