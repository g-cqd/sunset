import Foundation
import Testing

@testable import SunsetWebModel

/// By hand (SUNSET_CRX_PROBE=/path/to.crx): a real Web Store package verifies.
@Suite("real crx probe", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_CRX_PROBE"] != nil))
struct RealCRXProbe {
    @Test func `a Web Store package verifies`() throws {
        let path = try #require(ProcessInfo.processInfo.environment["SUNSET_CRX_PROBE"])
        let data = try Data(contentsOf: URL(filePath: path))
        let zip = try ExtensionPackage.zip(from: data)
        print("CRX verified; archive", zip.count, "bytes")
        var altered = data
        altered[altered.count - 10] ^= 1
        #expect(throws: ExtensionPackage.Refused.self) { try ExtensionPackage.zip(from: altered) }
    }
}
