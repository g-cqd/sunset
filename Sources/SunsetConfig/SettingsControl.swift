/// The control of an option of Settings. The app draws each kind; none is looked up by name.
public enum SettingsControl: Sendable {
    /// A switch; `label` when it says more than the option's title.
    case toggle(SettingsValue<Bool>, label: String?)
    /// A number in a range, with the step of its stepper, its unit and the digits shown after the point.
    case number(SettingsValue<Double>, ClosedRange<Double>, step: Double, unit: String, digits: Int)
    case choice(SettingsChoice, label: String?)
    case text(SettingsValue<String>, prompt: String)
    /// Text that is not set when it is empty.
    case optionalText(SettingsValue<String?>, prompt: String)
    /// A colour that can be left unset; `fallback` is what the picker starts from.
    case color(SettingsValue<[UInt8]?>, fallback: [UInt8])
    /// A radius that follows the window's corners, or a number of points of its own.
    case radius(SettingsValue<Double?>)
    case custom(Custom)

    /// The controls built by hand.
    public enum Custom: Sendable {
        case ansiPalette, scrollback, blinkTimeout, searchEngine, engines, websites, fileLocation, textOnlyZoom,
            siteAgents, profiles, features, blockingLists
        /// Settings, Storage (R12 step ST-6): what is sealed, the website data, the files set aside, the key, a code, export.
        case storageSealed, storageWebsiteData, storageSetAside, storageKey, storageEnterCode, storageExport
    }
}
