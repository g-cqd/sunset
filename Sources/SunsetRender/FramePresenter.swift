/// Where finished frames go (the platform seam of presentation): the macOS one keeps them in `IOSurface`s a layer can show. A presenter is told which pixel
/// rows of the surface changed since the last frame, so that it uploads those and nothing else.
public protocol FramePresenter: Sendable {
    /// `surface` is the whole frame; `changedRows` are the pixel rows that differ from the frame before it (the whole surface for the first).
    func present(_ surface: Surface, changedRows: ClosedRange<Int>)
}
