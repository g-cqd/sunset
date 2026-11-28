import Foundation

/// The outer header of a KDBX 4 database: its cipher, its compression, the seeds and the key derivation's parameters, as
/// KeePass writes them (fields of a 1-byte id and a 4-byte length; the derivation's as a variant dictionary).
struct KeePassHeader {
    enum Cipher {
        case aes256, chaCha20
    }

    /// The key derivation the database names, with what it needs.
    enum Derivation {
        case aes(rounds: UInt64, seed: [UInt8])
        case argon2(
            id: Bool,
            salt: [UInt8],
            memory: UInt64,
            iterations: UInt64,
            lanes: UInt32,
            secret: [UInt8],
            data: [UInt8]
        )
    }

    var cipher = Cipher.aes256
    var gzip = false
    var masterSeed: [UInt8] = []
    var iv: [UInt8] = []
    var derivation: Derivation?
    /// The header's bytes as written, which its hash and its HMAC cover.
    var bytes: [UInt8] = []

    /// Where the header ends in `file`: its hash and HMAC follow.
    var end = 0

    static let signature: [UInt8] = [0x03, 0xD9, 0xA2, 0x9A, 0x67, 0xFB, 0x4B, 0xB5]

    /// Reads the header of `file`; its version 4 and every field a KDBX 4 database must have.
    init(_ file: [UInt8]) throws(KeePassFile.Failure) {
        var reader = ByteReader(file)
        guard try reader.take(8) == Self.signature else { throw .notKeePass }
        _ = try reader.uint16()
        let major = try reader.uint16()
        guard major == 4 else { throw .unsupportedVersion(Int(major)) }
        var cipherFound = false
        loop: while true {
            let id = try reader.take(1)[0]
            let length = Int(try reader.uint32())
            let value = try reader.take(length)
            switch id {
                case 0: break loop
                case 2:
                    switch value {
                        case Self.aesCipher: cipher = .aes256
                        case Self.chaChaCipher: cipher = .chaCha20
                        default: throw .unsupportedCipher
                    }
                    cipherFound = true
                case 3: gzip = value.first == 1
                case 4: masterSeed = value
                case 7: iv = value
                case 11: derivation = try Self.derivation(value)
                default: continue
            }
        }
        end = reader.offset
        bytes = Array(file[0 ..< end])
        guard cipherFound, masterSeed.count == 32, derivation != nil,
            iv.count == (cipher == .aes256 ? 16 : 12)
        else { throw .damaged }
    }

    private static let aesCipher: [UInt8] = hex("31c1f2e6bf714350be5805216afc5aff")
    private static let chaChaCipher: [UInt8] = hex("d6038a2b8b6f4cb5a524339a31dbb59a")
    private static let aesKDF: [UInt8] = hex("c9d9f39a628a4460bf740d08c18a4fea")
    private static let argon2d: [UInt8] = hex("ef636ddf8c29444b91f7a9a403e30a0c")
    private static let argon2id: [UInt8] = hex("9e298b1956db4773b23dfc3ec6f0a1e6")

    static func hex(_ text: String) -> [UInt8] {
        stride(from: 0, to: text.count, by: 2)
            .compactMap { offset in
                let start = text.index(text.startIndex, offsetBy: offset)
                return UInt8(text[start ..< text.index(start, offsetBy: 2)], radix: 16)
            }
    }

    /// The key derivation's variant dictionary.
    private static func derivation(_ value: [UInt8]) throws(KeePassFile.Failure) -> Derivation {
        let items = try variants(value)
        func number(_ key: String) -> UInt64? {
            items[key].map { bytes in bytes.reversed().reduce(UInt64(0)) { $0 << 8 | UInt64($1) } }
        }
        guard let uuid = items["$UUID"] else { throw .damaged }
        switch uuid {
            case aesKDF:
                guard let rounds = number("R"), let seed = items["S"], seed.count == 32 else { throw .damaged }
                return .aes(rounds: rounds, seed: seed)
            case argon2d, argon2id:
                guard let salt = items["S"], let memory = number("M"), let iterations = number("I"),
                    let lanes = number("P"), number("V") == 0x13
                else { throw .unsupportedDerivation }
                return .argon2(
                    id: uuid == argon2id,
                    salt: salt,
                    memory: memory,
                    iterations: iterations,
                    lanes: UInt32(clamping: lanes),
                    secret: items["K"] ?? [],
                    data: items["A"] ?? []
                )
            default: throw .unsupportedDerivation
        }
    }

    /// A variant dictionary: version 1.x, then items of a type byte, a named key and a value, until a 0 type.
    static func variants(_ value: [UInt8]) throws(KeePassFile.Failure) -> [String: [UInt8]] {
        var reader = ByteReader(value)
        guard try reader.uint16() >> 8 == 1 else { throw .damaged }
        var items: [String: [UInt8]] = [:]
        while true {
            let type = try reader.take(1)[0]
            if type == 0 { return items }
            let key = String(decoding: try reader.take(Int(try reader.uint32())), as: UTF8.self)
            items[key] = try reader.take(Int(try reader.uint32()))
        }
    }
}
