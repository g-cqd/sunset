/// Full-width pixel rows of a frame's surface moved up or down, before the frame's operations: what a scroll does to the picture. A backend copies the
/// rows `sourceY ..< sourceY + height` to `destinationY ..< destinationY + height` as they were at the end of the frame before (the two may overlap).
public struct PixelMove: Sendable, Equatable {
    public let sourceY: Int
    public let destinationY: Int
    public let height: Int

    public init(sourceY: Int, destinationY: Int, height: Int) {
        self.sourceY = sourceY
        self.destinationY = destinationY
        self.height = height
    }
}
