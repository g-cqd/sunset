import Foundation
import MachO

/// The images loaded in this process, their links resolved (for `EngineFolder.running`).
enum EngineImages {
    static func loaded() -> [String] {
        (0 ..< _dyld_image_count())
            .compactMap { index in
                unsafe _dyld_get_image_name(index).map { unsafe String(cString: $0) }
            }
            .map { URL(filePath: $0).resolvingSymlinksInPath().path }
    }
}
