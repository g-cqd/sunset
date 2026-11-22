import Foundation
import WebKit

/// The second rung of appearing as another browser (the first is the User-Agent): what a page's scripts read to tell a
/// browser, read as the browser named in the User-Agent gives it. It runs before the page's own scripts, in every
/// frame, and decides by `navigator.userAgent` alone, so it always agrees with the header; with Safari's (Sunset as it
/// is) it does nothing.
///
/// Chrome and Edge (compared with Chrome Canary 160 on 2026-11-18): `navigator.vendor`, a `NavigatorUAData` with Chromium's brands and the fuller values when asked,
/// `navigator.deviceMemory`, a `window.chrome` with `app`, `csi` and `loadTimes`, and native functions written on one line, as V8 writes them. Firefox: an empty vendor,
/// `productSub`, `oscpu`, `buildID`. Both: what only Safari and an app's web view have (`navigator.standalone`, `GestureEvent`, `WebKitPoint`, the force-click handlers)
/// is gone, and what Sunset set reads as native. Nothing else: `window.webkit` (an app's web view's: it cannot be taken away), what the engine can and cannot do, its
/// error messages, how it lays out and draws, its workers, and the connection, are WebKit's, and a script that looks further can tell.
enum AgentScript {
    /// The processor's family as Chrome names it to `getHighEntropyValues`.
    static let architecture: String = {
        #if arch(arm64)
            "arm"
        #else
            "x86"
        #endif
    }()

    /// macOS's version as Chrome gives it (`platformVersion`): "27.2.1".
    static var platformVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// The memory in GB as Chrome rounds it (`navigator.deviceMemory`): down to a power of two, at least a quarter. 16 GB
    /// read 16 in Chrome 160; whether Chrome bounds it above is not probed.
    static var deviceMemory: Double {
        let gigabytes = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        return max(0.25, pow(2, floor(log2(max(gigabytes, 0.25)))))
    }

    /// `brands` as a script literal.
    static func literal(_ brands: [ChromiumBrands.Brand]) -> String {
        "[" + brands.map { "{brand:'\($0.brand)',version:'\($0.version)'}" }.joined(separator: ",") + "]"
    }

    @MainActor static func install(on configuration: WKWebViewConfiguration) {
        configuration.userContentController.addUserScript(
            WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
        )
    }

    static let source = make(
        chrome: literal(ChromiumBrands.list(major: AgentVersions.chrome, brand: "Google Chrome")),
        edge: literal(ChromiumBrands.list(major: AgentVersions.edge, brand: "Microsoft Edge")),
        platformVersion: platformVersion,
        architecture: architecture,
        memory: deviceMemory
    )
}
