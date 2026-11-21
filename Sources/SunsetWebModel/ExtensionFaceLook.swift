/// How an extension's button looks (the owner, 2026-11-21: unavailable in a document or a terminal, they "should be
/// disabled but also appear disabled": without colour, faded, blending with the window's chrome, not distracting).
package struct ExtensionFaceLook: Equatable, Sendable {
    /// 1: the icon's own colours; 0: grey.
    package let saturation: Double
    package let opacity: Double
    /// Drawn blending with what is under it (the chrome), not over it.
    package let blends: Bool

    package static func of(available: Bool) -> Self {
        available ? Self(saturation: 1, opacity: 1, blends: false) : Self(saturation: 0, opacity: 0.35, blends: true)
    }
}
