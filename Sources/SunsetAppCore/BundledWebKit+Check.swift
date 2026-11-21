/// Sunset WebKit refuses to run a WebKit other than its own (threat model: a program of the same user starting it with
/// loader variables, or swapping its frameworks for an older release's; library validation lets our team's older builds
/// load).
extension BundledWebKit {
    /// Why the WebKit loaded is not the app's.
    package enum Mismatch: Equatable, Sendable {
        /// A framework the app bundles was loaded from elsewhere (the path).
        case loadedFrom(String)
        /// The bundled WebKit was built from another base than the app was made with.
        case otherBase(app: String, framework: String?)
    }

    /// What is wrong with what is loaded.
    /// - Parameters:
    ///   - images: the paths of every image loaded in the process.
    ///   - bundled: the names the app bundles (`WebKit`, `WebCore`, …, `libwebrtc.dylib`).
    ///   - bundle: the app's path.
    ///   - appBase: the WebKit base the app was made with (its Info.plist's `SunsetWebKitBase`); nil for the native build.
    ///   - frameworkBase: the base the loaded WebKit framework records.
    ///   - resolve: a path with its links resolved (`/tmp` is `/private/tmp`), applied to the bundle's path and the images'.
    /// - Returns: what is wrong, or nil when the WebKit loaded is the app's own (or the build bundles none).
    package static func mismatch(
        images: [String],
        bundled: [String],
        bundle: String,
        appBase: String?,
        frameworkBase: String?,
        resolve: (String) -> String = { $0 }
    ) -> Mismatch? {
        guard let appBase else { return nil }
        let own = resolve(bundle) + "/Contents/Frameworks/"
        for image in images where bundled.contains(where: { names(image, $0) }) && !resolve(image).hasPrefix(own) {
            return .loadedFrom(image)
        }
        return frameworkBase == appBase ? nil : .otherBase(app: appBase, framework: frameworkBase)
    }

    /// Whether `image` is the bundled `name`: a framework's binary (`…/WebKit.framework/…/WebKit`) or a library.
    private static func names(_ image: String, _ name: String) -> Bool {
        name.hasSuffix(".dylib") ? image.hasSuffix("/" + name) : image.contains("/\(name).framework/")
    }
}
