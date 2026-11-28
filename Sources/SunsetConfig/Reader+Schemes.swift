internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// A plain setting's value. A look setting (`Configuration.schemeKeys`) has one per scheme (design 0009): one value is
    /// both schemes'; `{ "light": …, "dark": … }` each its own, and a scheme left out keeps what it had (macOS's). The dark
    /// one is the configuration's own; the light one is kept as JSON in `lightValues`. Any other setting reads the dark
    /// one of a pair, as files from when every setting could have two.
    mutating func readCodec(_ codec: SettingCodec, _ value: JSONValue) {
        noteFormerMaterial(codec.key, value)
        let scheme = Configuration.isSchemeKey(codec.key)
        guard case .object(let pair) = value, !pair.isEmpty || scheme,
            pair.keys.allSatisfy({ $0 == "light" || $0 == "dark" })
        else {
            let before = issues.count
            codec.read(&self, value)
            if scheme, issues.count == before { configuration.setLight(codec.key, codec.literal(configuration)) }
            return
        }
        guard scheme else {
            if let dark = pair["dark"] { codec.read(&self, dark) }
            return
        }
        schemeObjects.insert(codec.key)
        if let dark = pair["dark"] { codec.read(&self, dark) }
        guard let light = pair["light"] else { return }
        var scratch = Reader(configuration: configuration, scope: scope)
        codec.read(&scratch, light)
        issues += scratch.issues
        if scratch.issues.isEmpty { configuration.setLight(codec.key, codec.literal(scratch.configuration)) }
    }

    /// `window.material` was `opaque` (in a scheme): the window's own colour, which is a colour with no tint now.
    private mutating func noteFormerMaterial(_ key: String, _ value: JSONValue) {
        guard key == SettingsOption.materialKey else { return }
        func former(_ json: JSONValue?) -> Bool {
            guard case .string(let name) = json else { return false }
            return ["opaque", "fill", "transparent"].contains(name)
        }
        func opaque(_ json: JSONValue?) -> Bool {
            if case .string("opaque") = json { return true }
            return false
        }
        if case .object(let pair) = value {
            formerlyOpaque = (light: opaque(pair["light"]), dark: opaque(pair["dark"]))
            migrated = migrated || former(pair["light"]) || former(pair["dark"])
        } else {
            formerlyOpaque = (light: opaque(value), dark: opaque(value))
            migrated = migrated || former(value)
        }
    }

    /// What the former keys said, once every key is read: the tint's light keys (unless the tint has a value per scheme of
    /// its own), an opaque window, and `web.pageScheme`.
    mutating func finish() {
        let tintKeys = [SettingsOption.tintColorKey, SettingsOption.tintAlphaKey]
        if formerlyOpaque.dark {
            configuration.appearance.tintColor = nil
            configuration.appearance.tintAlpha = 1
        }
        if formerlyOpaque.light {
            configuration.setLight(tintKeys[0], "null")
            configuration.setLight(tintKeys[1], "1")
        } else {
            for key in tintKeys where !schemeObjects.contains(key) {
                if let literal = formerLight[key] { configuration.setLight(key, literal) }
            }
        }
        if let scheme = formerPageScheme { finishPageScheme(scheme) }
    }

    /// `web.pageScheme` as whether content follows the app's scheme: Sunset's (`app`) does; the system's does not; light or
    /// dark does when it is the app's scheme, and is said otherwise.
    private mutating func finishPageScheme(_ scheme: String) {
        let app = configuration.appearance.scheme.rawValue
        switch scheme {
            case "app": configuration.appearance.contentFollows = true
            case "system": configuration.appearance.contentFollows = false
            case app: configuration.appearance.contentFollows = true
            default:
                configuration.appearance.contentFollows = false
                issue(
                    "web.pageScheme",
                    "pages are no longer always \(scheme): they follow macOS's scheme, or Sunset's with "
                        + SettingsOption.contentFollowsKey
                )
        }
    }
}
