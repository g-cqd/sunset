import Testing

@testable import SunsetAppCore

/// Sunset WebKit runs only its own WebKit: every bundled framework from the app, at the base it was made with.
@Suite("Sunset WebKit refuses a WebKit not its own")
struct BundledWebKitCheckTests {
    private let bundle = "/Users/a/Applications/Sunset WebKit.app"
    private let bundled = ["WebKit", "WebCore", "JavaScriptCore", "libwebrtc.dylib"]
    private var own: [String] {
        [
            "/usr/lib/libSystem.B.dylib", "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit",
            bundle + "/Contents/Frameworks/WebKit.framework/Versions/A/WebKit",
            bundle + "/Contents/Frameworks/WebCore.framework/Versions/A/WebCore",
            bundle + "/Contents/Frameworks/JavaScriptCore.framework/Versions/A/JavaScriptCore",
            bundle + "/Contents/Frameworks/libwebrtc.dylib"
        ]
    }

    @Test func `its own frameworks at its own base pass; the native build is not checked`() {
        #expect(
            BundledWebKit.mismatch(
                images: own,
                bundled: bundled,
                bundle: bundle,
                appBase: "944f9ff",
                frameworkBase: "944f9ff"
            ) == nil
        )
        let system = ["/System/Library/Frameworks/WebKit.framework/Versions/A/WebKit"]
        #expect(
            BundledWebKit.mismatch(
                images: system,
                bundled: [],
                bundle: "/Applications/Sunset.app",
                appBase: nil,
                frameworkBase: nil
            ) == nil
        )
    }

    @Test func `the same place written through a link is the app's (/tmp and /private/tmp)`() {
        let app = "/tmp/copy/Sunset WebKit.app"
        let images = ["/private/tmp/copy/Sunset WebKit.app/Contents/Frameworks/WebKit.framework/Versions/A/WebKit"]
        #expect(
            BundledWebKit.mismatch(
                images: images,
                bundled: ["WebKit"],
                bundle: app,
                appBase: "a",
                frameworkBase: "a",
                resolve: {
                    $0.hasPrefix("/tmp/") ? "/private" + $0 : $0
                }
            ) == nil
        )
    }

    @Test func `a bundled framework loaded from elsewhere is refused, the system's included`() {
        let planted = "/tmp/old/WebCore.framework/Versions/A/WebCore"
        let images = own.map { $0.hasSuffix("/WebCore") ? planted : $0 }
        #expect(
            BundledWebKit.mismatch(images: images, bundled: bundled, bundle: bundle, appBase: "a", frameworkBase: "a")
                == .loadedFrom(planted)
        )
        let both = own + ["/System/Library/Frameworks/WebKit.framework/Versions/A/WebKit"]
        #expect(
            BundledWebKit.mismatch(images: both, bundled: bundled, bundle: bundle, appBase: "a", frameworkBase: "a")
                == .loadedFrom("/System/Library/Frameworks/WebKit.framework/Versions/A/WebKit")
        )
        let sibling = own + ["/Users/a/Applications/Sunset WebKit.app.old/Contents/Frameworks/libwebrtc.dylib"]
        #expect(
            BundledWebKit.mismatch(images: sibling, bundled: bundled, bundle: bundle, appBase: "a", frameworkBase: "a")
                != nil
        )
    }

    @Test func `frameworks of another base, an older release's swapped in, are refused`() {
        #expect(
            BundledWebKit.mismatch(
                images: own,
                bundled: bundled,
                bundle: bundle,
                appBase: "944f9ff",
                frameworkBase: "aa9b09c"
            )
                == .otherBase(app: "944f9ff", framework: "aa9b09c")
        )
        #expect(
            BundledWebKit.mismatch(
                images: own,
                bundled: bundled,
                bundle: bundle,
                appBase: "944f9ff",
                frameworkBase: nil
            ) != nil
        )
    }
}
