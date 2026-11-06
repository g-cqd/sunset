/// What the pointer did, in the terms a program can be told (xterm's mouse protocols). Positions are cells, counted from zero.
public struct MouseEvent: Sendable, Equatable {
    public enum Button: Sendable, Equatable {
        case left, middle, right
        case wheelUp, wheelDown, wheelLeft, wheelRight
        /// Motion with no button held.
        case none
    }

    public enum Action: Sendable, Equatable {
        case press, release, motion
    }

    public var action: Action
    public var button: Button
    public var modifiers: InputModifiers
    public var column: Int
    public var row: Int
    /// The position in pixels inside the grid, for the pixel format; zero when not known.
    public var pixelX: Int
    public var pixelY: Int

    public init(
        _ action: Action,
        _ button: Button,
        column: Int,
        row: Int,
        modifiers: InputModifiers = [],
        pixelX: Int = 0,
        pixelY: Int = 0
    ) {
        self.action = action
        self.button = button
        self.column = column
        self.row = row
        self.modifiers = modifiers
        self.pixelX = pixelX
        self.pixelY = pixelY
    }
}
