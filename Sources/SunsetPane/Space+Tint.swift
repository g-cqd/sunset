extension Space {
    /// The Space's colour: it tints the window that shows the Space, and nothing else. Kept in the look, as `#RRGGBB`;
    /// what is written there and is not a colour is no tint.
    public var tint: IconColor? {
        get {
            look?["tint"].flatMap(IconColor.init(hex:))
        }
        set {
            setLook("tint", newValue?.hex)
        }
    }

    /// Its colour in the light scheme, when it has one of its own (design 0009); nil: `tint` in both.
    public var lightTint: IconColor? {
        get {
            look?["tintLight"].flatMap(IconColor.init(hex:))
        }
        set {
            setLook("tintLight", newValue?.hex)
        }
    }

    /// The colour that tints its window in the scheme the window is drawn in.
    public func tint(light: Bool) -> IconColor? {
        light ? lightTint ?? tint : tint
    }

    private mutating func setLook(_ key: String, _ value: String?) {
        var kept = look ?? [:]
        kept[key] = value
        look = kept.isEmpty ? nil : kept
    }
}
