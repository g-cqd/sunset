import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Testing

@testable import SunsetShell

/// A picture pasted to set a one-time code up: an image on the pasteboard, or an image file copied in the Finder; text
/// alone is none. A pasteboard of the test's own, never the clipboard.
@MainActor @Suite("A picture on the pasteboard")
struct PasteboardImageTests {
    private func png() throws -> Data {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data("otpauth://totp/x?secret=JBSWY3DPEHPK3PXP".utf8)
        let image = try #require(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 6, y: 6))
        let cg = try #require(CIContext().createCGImage(image, from: image.extent))
        return try #require(NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]))
    }

    @Test func `an image, an image file, and text that is none`() throws {
        let board = NSPasteboard(name: NSPasteboard.Name("sunset-test-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }
        board.clearContents()
        board.setData(try png(), forType: .png)
        #expect(PasteboardImage.image(in: board) != nil)
        let file = FileManager.default.temporaryDirectory.appending(path: "qr-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }
        try png().write(to: file)
        board.clearContents()
        board.writeObjects([file as NSURL])
        #expect(PasteboardImage.image(in: board) != nil)
        board.clearContents()
        board.setString("not a picture", forType: .string)
        #expect(PasteboardImage.image(in: board) == nil)
    }
}
