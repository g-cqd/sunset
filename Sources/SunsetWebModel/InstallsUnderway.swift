/// The installs being fetched or asked about (seen 2026-11-21: one press on a store opened the prompt twice, one window in
/// the other): a second request for the same package into the same profile, while the first is underway, is dropped.
package struct InstallsUnderway {
    private var underway: Set<String> = []

    package init() {}

    /// Whether the install of `package` into `profile` may start (false: one is underway); it is underway until `end`.
    package mutating func begin(_ package: String, profile: String?) -> Bool {
        underway.insert(Self.key(package, profile)).inserted
    }

    package mutating func end(_ package: String, profile: String?) {
        underway.remove(Self.key(package, profile))
    }

    private static func key(_ package: String, _ profile: String?) -> String {
        package + "\u{0}" + (profile ?? "")
    }
}
