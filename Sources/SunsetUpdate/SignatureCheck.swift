public import Foundation
internal import Security

/// Whether a staged bundle may replace the running one (ADR-0122): signed by Apple's Developer ID chain for our team,
/// notarized, the running app's identifier, every nested piece of code valid; and a later build. What it came from (a
/// delta, a zip, GitHub) is not trusted: this is.
public enum SignatureCheck {
    public enum Failure: Error, Equatable {
        /// Its signature could not be read (unsigned, broken).
        case unreadable(Int32)
        /// Signed, but not as the requirement says (another team, another identifier, not notarized), or not valid.
        case refused(Int32)
        /// Not a later build than the running one.
        case notLater(running: Int, staged: Int?)
    }

    /// The requirement an update of the app `identifier` by `team` must meet.
    public static func requirement(team: String, identifier: String) -> String {
        "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\" and identifier \"\(identifier)\" and notarized"
    }

    /// Checks the bundle at `bundle` against `requirement`, its nested code included.
    public static func check(bundle: URL, requirement: String) throws(Failure) {
        var code: SecStaticCode?
        let created = unsafe SecStaticCodeCreateWithPath(bundle as CFURL, [], &code)
        guard created == errSecSuccess, let code else { throw .unreadable(created) }
        var compiled: SecRequirement?
        let parsed = unsafe SecRequirementCreateWithString(requirement as CFString, [], &compiled)
        guard parsed == errSecSuccess, let compiled else { throw .refused(parsed) }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        let status = SecStaticCodeCheckValidity(code, flags, compiled)
        guard status == errSecSuccess else { throw .refused(status) }
    }

    /// Checks that the staged bundle's build (`CFBundleVersion`, a count) is later than `running`, or equal when
    /// `allowingEqual` is true (a same-build variant switch between System WebKit and Sunset's WebKit, ADR-0125).
    public static func checkLater(bundle: URL, than running: Int, allowingEqual: Bool = false) throws(Failure) {
        let info = NSDictionary(contentsOf: bundle.appending(path: "Contents/Info.plist"))
        let staged = (info?["CFBundleVersion"] as? String).flatMap { Int($0) }
        guard let staged, allowingEqual ? staged >= running : staged > running else {
            throw .notLater(running: running, staged: staged)
        }
    }

    /// The team that signed the running process, nil when it has none (a development build: no updates).
    public static func runningTeam() -> String? {
        var code: SecCode?
        guard unsafe SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard unsafe SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard unsafe SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess else { return nil }
        return (information as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String
    }
}
