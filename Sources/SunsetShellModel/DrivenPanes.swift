import Observation
import SunsetRuntime

/// The panes a program drives from outside (`sunset`, ADR-0129): read, typed into or waited on in the last seconds. Their
/// tab shows it, with a control that stops it: a pane stopped refuses the tool until the app quits.
@MainActor @Observable
package final class DrivenPanes {
    package static let shared = DrivenPanes()

    /// How long a pane stays marked after the tool last asked about it.
    @ObservationIgnored package var hold: Duration = .seconds(10)
    private var driven: [ObjectIdentifier: Int] = [:]
    @ObservationIgnored private var refused: Set<ObjectIdentifier> = []

    package init() {}

    /// The tool asks about `content`: false when it was stopped; else its tab is marked for `hold`.
    package func drive(_ content: some AnyObject) -> Bool {
        let key = ObjectIdentifier(content)
        guard !refused.contains(key) else { return false }
        let turn = (driven[key] ?? 0) + 1
        driven[key] = turn
        let hold = hold
        Runtime.live.task { [weak self] in
            await Runtime.live.sleep(for: hold)
            // Only the last request's wait takes the mark away.
            if self?.driven[key] == turn { self?.driven[key] = nil }
        }
        return true
    }

    /// Whether its tab shows the mark.
    package func isDriven(_ content: some AnyObject) -> Bool {
        driven[ObjectIdentifier(content)] != nil
    }

    /// The person stopped it: the mark goes, and the tool is refused this pane.
    package func stop(_ content: some AnyObject) {
        let key = ObjectIdentifier(content)
        refused.insert(key)
        driven[key] = nil
    }
}
