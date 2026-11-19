/// What a profile sets otherwise than all profiles (the owner's notes n1, n38; roadmap 0050): only the keys a profile may
/// set (`profileKeys`), each kept as the file writes it, and only where it differs from all profiles. What a profile never
/// changed follows all profiles.
public enum ProfileOverrides {
    /// The keys a profile may set otherwise: search, privacy, network, downloads (the owner's answer, 2026-11-18).
    public static let profileKeys: [String] =
        [
            "web.engine", "web.suggestions", "web.privateSuggestions",
            "web.blocking", "web.agent", "web.agentScripts", "web.keep.cache", "web.keep.traces", "web.keep.siteData",
            "web.proxy",
            "web.downloadFolder", "web.askWhereToSave"
        ] + Configuration.Web.permissionNames.map { "web.permissions.\($0)" }

    static let keySet = Set(profileKeys)

    /// The keys of `profile` that differ from `app`'s, each as the file writes it.
    public static func diff(profile: Configuration, app: Configuration) -> [String: String] {
        let mine = ConfigurationWriter.literals(for: profile)
        let theirs = ConfigurationWriter.literals(for: app)
        var overrides: [String: String] = [:]
        for key in profileKeys where mine[key] != theirs[key] { overrides[key] = mine[key] ?? "null" }
        return overrides
    }

    /// `app` with a profile's own values; keys a profile may not set are left as they are.
    public static func apply(_ overrides: [String: String], to app: Configuration) -> Configuration {
        let allowed = Set(profileKeys)
        let own = overrides.filter { allowed.contains($0.key) }
        guard !own.isEmpty else { return app }
        // As a file of these keys only, read onto all profiles' settings.
        var root: [String: Any] = [:]
        for (key, literal) in own { insert(literal, at: key.split(separator: ".").map(String.init), into: &root) }
        let text = render(root)
        return (try? ConfigurationParser.parse(text, base: app).configuration) ?? app
    }

    private static func insert(_ literal: String, at path: [String], into node: inout [String: Any]) {
        guard let first = path.first else { return }
        if path.count == 1 {
            node[first] = literal
            return
        }
        var child = node[first] as? [String: Any] ?? [:]
        insert(literal, at: Array(path.dropFirst()), into: &child)
        node[first] = child
    }

    private static func render(_ node: [String: Any]) -> String {
        let fields = node.keys.sorted()
            .map { key -> String in
                let value = node[key]
                let text = (value as? [String: Any]).map(render) ?? (value as? String ?? "null")
                return ConfigurationWriter.string(key) + ": " + text
            }
        return "{" + fields.joined(separator: ", ") + "}"
    }
}

extension SettingsOption {
    /// A profile can set it otherwise (roadmap 0050): one of the keys it writes is a profile's.
    public var isProfileSetting: Bool {
        // Each site: a profile's own site rules (roadmap 0050 E).
        id == "web.sites" || keys.contains { ProfileOverrides.keySet.contains($0) }
    }
}

extension SettingsTopic {
    /// It has something a profile can set otherwise.
    public var hasProfileSettings: Bool {
        (first + further).contains(where: \.isProfileSetting)
    }
}
