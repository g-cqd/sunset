extension Design {
    /// How a control answers a press.
    package enum Motion {
        /// A glyph button's size while pressed: it gives a little under the pointer.
        package static let pressedScale = 0.9
        /// How long a folder takes to fold or unfold, its rows sliding in or out: as `Fold`'s.
        package static let foldDuration = 0.15
    }
}
