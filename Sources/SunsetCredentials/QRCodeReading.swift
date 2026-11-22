public import CoreGraphics
import Vision

/// One-time codes read from a QR code's picture (roadmap 0093 D): on this Mac, by Vision; nothing is sent anywhere. Each
/// QR code in the picture that is an `otpauth://` link, or Google Authenticator's export, gives its codes; any other
/// (a web address) is left out.
public enum QRCodeReading {
    public static func codes(in image: CGImage) async throws -> [OneTimeCodeURI] {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]
        let found = try await request.perform(on: image)
        return found.compactMap(\.payloadString).flatMap(codes(from:))
    }

    /// What a QR code's text gives: one code, an export's codes, or none.
    static func codes(from text: String) -> [OneTimeCodeURI] {
        if let code = try? OneTimeCodeURI(text) { return [code] }
        return (try? AuthenticatorMigration(text).codes) ?? []
    }
}
