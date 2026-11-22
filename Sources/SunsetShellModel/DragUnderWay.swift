import Observation

/// The drag of tabs under way in the app, whichever window it started in: every window's gaps take drops while it is
/// set.
@MainActor @Observable
package final class DragUnderWay {
    package static let shared = DragUnderWay()
    package weak var origin: TabsModel?
}
