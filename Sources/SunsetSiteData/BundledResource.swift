import Foundation

/// The files this module ships in `Resources/` (see `Resources/SOURCES.md`), read from its bundle.
enum BundledResource {
    /// The bytes of `Resources/<name>.<ext>`, or nil when the file is not there or cannot be read.
    static func data(_ name: String, _ ext: String) -> Data? {
        Bundle.module.url(forResource: "Resources/\(name)", withExtension: ext).flatMap { try? Data(contentsOf: $0) }
    }

    /// The UTF-8 text of `Resources/<name>.<ext>`, or nil when it is not there or not UTF-8.
    static func text(_ name: String, _ ext: String) -> String? {
        data(name, ext).flatMap { String(data: $0, encoding: .utf8) }
    }
}
