internal import Security

/// How this program is signed: its team, for a build signed by one (a release, a team-signed development build); nil for an
/// ad-hoc or unsigned build.
enum CodeSigning {
    static let teamIdentifier: String? = {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess,
            let fields = information as? [String: Any]
        else { return nil }
        return fields[kSecCodeInfoTeamIdentifier as String] as? String
    }()
}
