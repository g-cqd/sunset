extension Space {
    /// The Space's colour (the owner, 2026-11-17): it tints the window that shows the Space, and nothing else. Kept in the
    /// look, as `#RRGGBB`; what is written there and is not a colour is no tint.
    public var tint: IconColor? {
        get { look?["tint"].flatMap(IconColor.init(hex:)) }
        set {
            var kept = look ?? [:]
            kept["tint"] = newValue?.hex
            look = kept.isEmpty ? nil : kept
        }
    }
}
