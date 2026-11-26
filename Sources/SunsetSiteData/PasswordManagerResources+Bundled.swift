import Foundation

extension PasswordManagerResources {
    /// The resources Sunset ships, read once and kept.
    public static func bundled() throws -> PasswordManagerResources {
        guard let resources = shared else { throw CocoaError(.fileNoSuchFile) }
        return resources
    }

    private static let shared: PasswordManagerResources? = {
        func data(_ name: String) -> Data? {
            BundledResource.data(name, "json")
        }
        guard let rules = data("password-rules"), let shared = data("shared-credentials"),
            let pages = data("change-password-URLs"), let suffixes = try? PublicSuffixList.bundled()
        else { return nil }
        return PasswordManagerResources(
            passwordRules: rules,
            sharedCredentials: shared,
            changePasswordURLs: pages,
            suffixes: suffixes
        )
    }()
}
