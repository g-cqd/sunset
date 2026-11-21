import Foundation
import MachO

extension BundledWebKit {
    /// After `runAgainIfNeeded`, before anything else: ends the process when the WebKit loaded is not the app's own, saying
    /// why on the standard error. The native build has nothing to check.
    package static func refuseOtherWebKit() {
        let main = Bundle.main
        guard let info = main.infoDictionary, let appBase = info[marker] as? String else { return }
        let frameworks = main.bundlePath + "/Contents/Frameworks"
        let bundled = ((try? FileManager.default.contentsOfDirectory(atPath: frameworks)) ?? [])
            .map {
                $0.hasSuffix(".framework") ? String($0.dropLast(".framework".count)) : $0
            }
        let images = (0 ..< _dyld_image_count())
            .compactMap { index in
                unsafe _dyld_get_image_name(index).map { unsafe String(cString: $0) }
            }
        let webKitInfo = frameworks + "/WebKit.framework/Versions/A/Resources/Info.plist"
        let frameworkBase = NSDictionary(contentsOfFile: webKitInfo)?[marker] as? String
        guard
            let wrong = mismatch(
                images: images,
                bundled: bundled,
                bundle: main.bundlePath,
                appBase: appBase,
                frameworkBase: frameworkBase,
                resolve: { URL(filePath: $0).resolvingSymlinksInPath().path }
            )
        else { return }
        FileHandle.standardError.write(Data("Sunset WebKit: not its own WebKit (\(wrong)); it does not run\n".utf8))
        exit(78)
    }
}
