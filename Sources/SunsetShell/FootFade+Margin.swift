extension FootFade {
    /// The room under a list's last row above its foot: `margin`, and at least the fade's height when the foot fades it,
    /// so that the last row scrolled to the end shows whole (n134).
    package static func margin(_ margin: Double, faded: Bool) -> Double {
        faded ? max(margin, Design.Space.xl) : margin
    }
}
