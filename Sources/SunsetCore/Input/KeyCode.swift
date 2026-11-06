/// A key, as the host reports it: the character keys by the character they are (the unshifted one), the others by name.
public enum KeyCode: Sendable, Equatable {
    case character(Unicode.Scalar)
    case enter, tab, backspace, escape
    case up, down, left, right
    case home, end, pageUp, pageDown, insert, delete
    /// F1 ... F24.
    case function(Int)
}
