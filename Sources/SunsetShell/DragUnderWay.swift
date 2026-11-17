import Observation

/// The drag of tabs under way in the app, whichever window it started in (roadmap 0038 F): every window's gaps take drops
/// while it is set.
@MainActor @Observable
final class DragUnderWay {
    static let shared = DragUnderWay()
    weak var origin: TabsModel?
}
