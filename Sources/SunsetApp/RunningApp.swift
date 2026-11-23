import Foundation
import SunsetAppCore
import SunsetUpdate

/// The running app as an update sees it: where it is, its build, which flavour.
struct RunningApp: Sendable {
    let bundle: URL
    let build: Int
    let version: String
    let flavour: Flavour
    let identifier: String

    static var current: Self {
        let info = Bundle.main.infoDictionary ?? [:]
        return Self(
            bundle: Bundle.main.bundleURL,
            build: Int(info["CFBundleVersion"] as? String ?? "") ?? 0,
            version: info["CFBundleShortVersionString"] as? String ?? "",
            flavour: info[BundledWebKit.marker] == nil ? .native : .webKit,
            identifier: Bundle.main.bundleIdentifier ?? ""
        )
    }

    /// The archives' architecture for this process.
    static var architecture: String {
        #if arch(arm64)
            "arm64"
        #else
            "x86_64"
        #endif
    }

    /// Where an update is staged: beside the app (one volume, for the swap), hidden.
    var staging: URL {
        bundle.deletingLastPathComponent()
            .appending(path: ".\(bundle.deletingPathExtension().lastPathComponent)-update.app")
    }
}
