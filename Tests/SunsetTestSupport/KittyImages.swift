internal import Foundation

/// kitty graphics escapes for the render tests, CPU and Metal (ADR-0117): images of one colour (`rgba`: its four bytes), sent and shown at the cursor.
public enum KittyImages {
    /// Sends a `width` × `height` RGBA image of one colour as image `id` and shows it at the cursor (`a=T`), the cursor left
    /// where it was (`C=1`), with `options` added (`z=-1`, `c=3,r=2`).
    public static func show(
        id: Int,
        width: Int,
        height: Int,
        rgba: [UInt8],
        options: String = ""
    ) -> String {
        let pixels = Array(repeatElement(rgba, count: width * height).joined())
        return show(id: id, width: width, height: height, pixels: pixels, options: options)
    }

    /// The same with the RGBA bytes given, rows top to bottom; sent in chunks of 4,096 bytes, as kitty's clients send.
    public static func show(id: Int, width: Int, height: Int, pixels: [UInt8], options: String = "") -> String {
        let extra = options.isEmpty ? "" : ",\(options)"
        return chunked("a=T,C=1,q=2,f=32,i=\(id),s=\(width),v=\(height)\(extra)", Data(pixels).base64EncodedString())
    }

    /// `payload` in escapes of at most 4,096 of its bytes, the first with `control`, each saying whether more follow (`m`).
    private static func chunked(_ control: String, _ payload: String) -> String {
        let bytes = Array(payload.utf8)
        var out = ""
        var start = 0
        repeat {
            let end = min(start + 4_096, bytes.count)
            let head = start == 0 ? "\(control),m=\(end < bytes.count ? 1 : 0)" : "m=\(end < bytes.count ? 1 : 0)"
            out += "\u{1B}_G\(head);\(String(decoding: bytes[start ..< end], as: UTF8.self))\u{1B}\\"
            start = end
        } while start < bytes.count
        return out
    }

    /// Sends `file` as PNG image `id` and shows it at the cursor, the cursor left where it was.
    public static func showPNG(id: Int, _ file: [UInt8]) -> String {
        chunked("a=T,C=1,q=2,f=100,i=\(id)", Data(file).base64EncodedString())
    }

    /// Takes every image off the screen (`a=d`, `d=a`).
    public static let deleteAll = "\u{1B}_Ga=d,d=a,q=2\u{1B}\\"
}
