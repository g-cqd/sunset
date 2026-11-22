/// A PNG file's size, read from its signature and its first chunk (IHDR), never past its end; the pixels are the
/// renderer's to decode.
enum PNGHeader {
    private static let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    private static let header: [UInt8] = Array("IHDR".utf8)

    static func size(_ file: [UInt8]) -> (width: Int, height: Int)? {
        guard file.count >= 24, file.prefix(8).elementsEqual(signature), file[12 ..< 16].elementsEqual(header) else {
            return nil
        }
        let big = { (at: Int) in file[at ..< at + 4].reduce(0) { $0 << 8 | Int($1) } }
        return (big(16), big(20))
    }
}
