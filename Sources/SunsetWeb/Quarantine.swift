import CoreServices
import Foundation

/// The mark macOS puts on what comes from the Internet (Gatekeeper checks a marked file when it is first opened), with the file's address and the page
/// it was downloaded from.
enum Quarantine {
    static func mark(_ file: URL, source: URL?, origin: URL?) {
        var properties: [String: Any] = [
            kLSQuarantineAgentNameKey as String: "Sunset",
            kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload as String
        ]
        if let source { properties[kLSQuarantineDataURLKey as String] = source }
        if let origin { properties[kLSQuarantineOriginURLKey as String] = origin }
        var values = URLResourceValues()
        values.quarantineProperties = properties
        var target = file
        try? target.setResourceValues(values)
    }
}
