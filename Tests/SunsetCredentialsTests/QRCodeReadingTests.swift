import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Testing

@testable import SunsetCredentials

/// One-time codes from a QR code's picture (roadmap 0093 D): read on this Mac by Vision, nothing sent anywhere. The
/// picture here is made by Core Image's own QR generator: an `otpauth://` link, and a picture with none.
@Suite("Codes from a QR code's picture")
struct QRCodeReadingTests {
    private func picture(_ text: String) throws -> CGImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        let image = try #require(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        return try #require(CIContext().createCGImage(image, from: image.extent))
    }

    @Test func `an otpauth link in a picture gives its code; a picture with no code gives none`() async throws {
        let link = "otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&issuer=Example"
        let codes = try await QRCodeReading.codes(in: try picture(link))
        #expect(codes.map(\.account) == ["alice"] && codes.first?.issuer == "Example")
        let none = try await QRCodeReading.codes(in: try picture("https://example.com"))
        #expect(none.isEmpty)
    }
}
