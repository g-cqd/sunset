import SunsetMetrics

extension SettingsOption {
    /// The numbers of `layout.*` named by `keys`, in that order, from `Configuration.Layout.fields`: each is shown with the
    /// thing it measures. A key that is not a field gives nothing, and a field placed nowhere has no control, which the tests
    /// refuse.
    static func layout(_ keys: String...) -> [Self] {
        keys.compactMap { key in
            guard let field = Configuration.Layout.fields.first(where: { $0.key == key }) else { return nil }
            let value = SettingsValue<Double>(
                get: { $0.layout[keyPath: field.path] },
                set: { $0.layout[keyPath: field.path] = $1 }
            )
            let words = (field.keywords + ["layout", "spacing", "padding", "margin", "radius"]).joined(separator: " ")
            return Self(
                "layout.\(field.key)",
                field.title,
                words,
                .number(value, field.range, step: field.step, unit: field.unit, digits: 2)
            )
            // The measures are a level down (roadmap 0047 G).
            .further
        }
    }
}
