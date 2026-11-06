import SunsetCore

/// What the window sends to the program, in the order it happened.
enum InputEvent: Sendable {
    case key(KeyPress)
    case text(String)
    case paste(String)
    case mouse(MouseEvent)
}
