/// What a tab says it is capturing by its mark (the model's word; its colour is the view's, `PaneCaptureMark.color`).
package enum PaneCaptureMark: Equatable, Sendable {
    /// The camera or the microphone.
    case cameraOrMicrophone
    /// A screen, or this tab shared into a call (ADR-0082).
    case screen
}
