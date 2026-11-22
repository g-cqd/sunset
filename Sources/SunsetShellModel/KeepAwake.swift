/// Until when a tab or a window keeps the Mac awake ("as long as it is running"; his answer: both, chosen).
package enum KeepAwake: Equatable, Sendable {
    /// Until the tab, or the window, is closed.
    case closed
    /// Until the command that runs in it ends (a window: until none of its tabs runs one). It does not wait for the next.
    case commandEnds
}
