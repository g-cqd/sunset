package import Foundation

/// What a page sees of the browser (R1: the system's WebKit, named as the installed Safari; the owner: "make it appear as Safari by default"). WebKit
/// writes the start of the user agent (`Mozilla/5.0 (Macintosh; …) AppleWebKit/605.1.15 (KHTML, like Gecko)`); this is the end Safari adds to it.
package enum SafariName {
    /// The token Safari has put after its version since 2017; it no longer changes with releases.
    static let safariToken = "Safari/605.1.15"

    /// `Version/<Safari's version> Safari/605.1.15`, from the Info.plist given (the installed Safari's by default); `Safari/605.1.15` alone when no version
    /// can be read.
    package static func applicationName(
        infoPlist: URL = URL(fileURLWithPath: "/Applications/Safari.app/Contents/Info.plist")
    ) -> String {
        guard let data = try? Data(contentsOf: infoPlist),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let version = plist["CFBundleShortVersionString"] as? String,
            version.allSatisfy({ $0.isNumber || $0 == "." }), !version.isEmpty
        else { return safariToken }
        return "Version/\(version) \(safariToken)"
    }
}
