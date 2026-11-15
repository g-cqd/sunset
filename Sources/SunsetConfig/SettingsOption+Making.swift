/// The short ways to declare an option of each kind.
extension SettingsOption {
    typealias Path<Value> = any WritableKeyPath<Configuration, Value> & Sendable

    static func toggle(_ id: String, _ title: String, _ words: String, _ path: Path<Bool>, label: String? = nil) -> Self
    {
        Self(id, title, words, .toggle(SettingsValue(path), label: label))
    }

    static func number(
        _ id: String,
        _ title: String,
        _ words: String,
        _ path: Path<Double>,
        _ range: ClosedRange<Double>,
        step: Double,
        unit: String = "pt",
        digits: Int = 2
    ) -> Self {
        Self(id, title, words, .number(SettingsValue(path), range, step: step, unit: unit, digits: digits))
    }

    static func choice<Value: RawRepresentable & Sendable>(
        _ id: String,
        _ title: String,
        _ words: String,
        _ path: Path<Value>,
        _ items: [(Value, String)],
        label: String? = nil
    ) -> Self where Value.RawValue == String {
        Self(id, title, words, .choice(SettingsChoice(path, items), label: label))
    }

    static func text(_ id: String, _ title: String, _ words: String, _ path: Path<String>, prompt: String) -> Self {
        Self(id, title, words, .text(SettingsValue(path), prompt: prompt))
    }

    static func color(_ id: String, _ title: String, _ words: String, _ path: Path<[UInt8]?>, _ fallback: [UInt8])
        -> Self
    {
        Self(id, title, words, .color(SettingsValue(path), fallback: fallback))
    }

    static func custom(_ id: String, _ title: String, _ words: String, _ custom: SettingsControl.Custom) -> Self {
        Self(id, title, words, .custom(custom))
    }
}
