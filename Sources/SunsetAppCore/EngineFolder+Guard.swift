import Foundation
import MachO

extension EngineFolder {
    /// Before anything else: a process that mixes the engine's WebKit with the system's (an engine half-installed, a
    /// framework missing) sets the engine's folder aside and runs again, on the system's, saying so on the standard error
    /// (ADR-0124; diary 2026-11-23-08). Nothing to do on the system's or on a whole engine, nor in Sunset WebKit (its own).
    package static func setAsideIfMixed() {
        let main = Bundle.main
        guard main.infoDictionary?[BundledWebKit.marker] == nil else { return }
        let app = URL(filePath: main.bundlePath).resolvingSymlinksInPath().path
        let images = (0 ..< _dyld_image_count())
            .compactMap { index in
                unsafe _dyld_get_image_name(index).map { unsafe String(cString: $0) }
            }
            .map { URL(filePath: $0).resolvingSymlinksInPath().path }
        guard case .mixed(let part) = running(images: images, engine: frameworks(app: app)) else { return }
        let aside = setAside(app: app)
        try? FileManager.default.removeItem(atPath: aside)
        guard (try? FileManager.default.moveItem(atPath: folder(app: app), toPath: aside)) != nil else { return }
        let said =
            "Sunset: its WebKit engine is incomplete (\(part) is not in it); set aside at \(aside), running again\n"
        FileHandle.standardError.write(Data(said.utf8))
        let arguments = CommandLine.arguments
        let pointers = arguments.map { unsafe strdup($0) } + [nil]
        unsafe execv(main.executablePath ?? arguments[0], pointers)
        exit(78)
    }
}
