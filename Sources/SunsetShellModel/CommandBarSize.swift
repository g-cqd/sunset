/// The command bar's size in the room it has (in a small window it went past its edges).
package enum CommandBarSize {
    /// Its own width while it fits; else the room less a margin on each side.
    package static func width(room: Double) -> Double {
        min(Design.Width.commandBar, max(0, room - 2 * Design.Space.l))
    }

    /// The most it may be tall: what is under its top, less a margin; its rows scroll inside.
    package static func height(room: Double, top: Double) -> Double {
        max(0, room - top - Design.Space.l)
    }
}
