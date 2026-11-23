public import Foundation
internal import Security

/// Whether a staged engine may be put in place (ADR-0124): its manifest (in its signed WebKit Info.plist) says a later
/// build than the one installed, everything in its `Frameworks` is a framework or a library, and each meets `requirement`
/// (the app's: our team, notarized), its nested code included. Library validation then lets only our team's code load.
public enum EngineCheck {
    public enum Failure: Error, Equatable {
        case noManifest
        case notLater(installed: Int, staged: Int)
        /// Something in Frameworks that is not a framework or a library.
        case unexpected(String)
        /// A framework or library whose signature does not meet the requirement (or has none).
        case refused(String)
    }

    /// Checks the engine folder at `engine` against `requirement`, later than build `after` (0: none installed).
    public static func check(_ engine: URL, requirement: String, after: Int) throws(Failure) {
        guard let manifest = EngineManifest.read(from: engine) else { throw .noManifest }
        guard manifest.build > after else { throw .notLater(installed: after, staged: manifest.build) }
        let frameworks = engine.appending(path: "Frameworks")
        let items = ((try? FileManager.default.contentsOfDirectory(atPath: frameworks.path)) ?? []).sorted()
        if let other = items.first(where: { !$0.hasSuffix(".framework") && !$0.hasSuffix(".dylib") }) {
            throw .unexpected(other)
        }
        // WebKit first: the one whose Info.plist the manifest is read from.
        for item in items.filter({ $0 == "WebKit.framework" }) + items.filter({ $0 != "WebKit.framework" }) {
            guard meets(frameworks.appending(path: item), requirement) else { throw .refused(item) }
        }
    }

    private static func meets(_ code: URL, _ requirement: String) -> Bool {
        var staticCode: SecStaticCode?
        var compiled: SecRequirement?
        guard unsafe SecStaticCodeCreateWithPath(code as CFURL, [], &staticCode) == errSecSuccess, let staticCode,
            unsafe SecRequirementCreateWithString(requirement as CFString, [], &compiled) == errSecSuccess, let compiled
        else { return false }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        return SecStaticCodeCheckValidity(staticCode, flags, compiled) == errSecSuccess
    }
}
