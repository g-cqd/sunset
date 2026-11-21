extension Design {
    /// How a control answers a press (the owner's note n11).
    package enum Motion {
        /// A glyph button's size while pressed: it gives a little under the pointer.
        package static let pressedScale = 0.9
        /// How long a folder takes to fold or unfold, its rows sliding in or out (the owner's note n76): as `Fold`'s.
        package static let foldDuration = 0.15
    }
}
