import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// What WebKit loads from what the person picks. `.xpi` and `.zip` are zips; a Chrome Web Store `.crx` (CRX3) is a zip
/// behind a header ("Cr24", the version 3, the header's length, the header); WebKit takes a zip as it is.
@Suite("An extension's package")
struct ExtensionPackageTests {
    static let zipStart = Data([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00])

    static func crx3(header: Data, zip: Data) -> Data {
        var data = Data("Cr24".utf8)
        withUnsafeBytes(of: UInt32(3).littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(header.count).littleEndian) { data.append(contentsOf: $0) }
        return data + header + zip
    }

    @Test func `a zip is a zip; a CRX3 is its zip; anything else is refused`() throws {
        #expect(try ExtensionPackage.zip(from: Self.zipStart) == Self.zipStart)
        let crx = Self.crx3(header: Data(repeating: 7, count: 40), zip: Self.zipStart)
        #expect(try ExtensionPackage.zip(from: crx) == Self.zipStart)
        #expect(throws: ExtensionPackage.Refused.self) { try ExtensionPackage.zip(from: Data("<html>".utf8)) }
        var crx2 = Data("Cr24".utf8)
        withUnsafeBytes(of: UInt32(2).littleEndian) { crx2.append(contentsOf: $0) }
        #expect(throws: ExtensionPackage.Refused.self) { try ExtensionPackage.zip(from: crx2 + Self.zipStart) }
        #expect(throws: ExtensionPackage.Refused.self) {
            try ExtensionPackage.zip(from: Self.crx3(header: Data(count: 4), zip: Data()).prefix(14))
        }
    }

    /// A package a page offers (a store's "Download file", a link to a `.crx`) is installed, not downloaded.
    @Test func `an extension's package is told by its type or its name`() {
        #expect(ExtensionPackage.isPackage(mime: "application/x-chrome-extension", path: "/x"))
        #expect(ExtensionPackage.isPackage(mime: "application/x-xpinstall", path: "/x"))
        #expect(ExtensionPackage.isPackage(mime: "application/octet-stream", path: "/files/ublock_origin-1.76.4.xpi"))
        #expect(ExtensionPackage.isPackage(mime: nil, path: "/a.CRX"))
        #expect(!ExtensionPackage.isPackage(mime: "application/zip", path: "/a.zip"), "a zip is a download")
        #expect(!ExtensionPackage.isPackage(mime: "text/html", path: "/addon/x/"))
    }
}
