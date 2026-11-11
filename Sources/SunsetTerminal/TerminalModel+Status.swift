import SunsetCore
import SunsetHost

extension TerminalModel {
    /// What the tab shows: changed only when it differs, so that nothing observing it redraws for nothing.
    func apply(_ status: TerminalStatus) {
        let shown = status.title.isEmpty ? "Sunset" : status.title
        if shown != title { title = shown }
        let path = status.workingDirectory?.path
        if path != directory { directory = path }
        let fraction = Self.fraction(of: status.progress)
        if fraction != progress { progress = fraction }
    }
}
