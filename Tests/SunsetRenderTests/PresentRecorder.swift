import Synchronization

@testable import SunsetRender

/// A presenter that records the pixel rows it was told changed.
final class PresentRecorder: FramePresenter {
    let calls = Mutex<[ClosedRange<Int>]>([])
    func present(_ surface: Surface, changedRows: ClosedRange<Int>) { calls.withLock { $0.append(changedRows) } }
}
