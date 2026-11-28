internal import AemiArgon2
import CryptoKit
public import Foundation

/// A KeePass database (KDBX 4.0) written from the vault's entries, protected by a password the person gives: ChaCha20,
/// Argon2id (64 MiB, 4 passes, 2 lanes), no compression; its passwords and every secret field protected in it; its
/// attachments in the inner header. KeePass 2 and KeePassXC open it.
public enum KeePassWriter {
    /// The derivation's cost: KeePassXC's default memory, Argon2id.
    static let memory: UInt64 = 64 << 20
    static let passes: UInt64 = 4
    static let lanes: UInt32 = 2

    public enum Failure: Error, Equatable, Sendable {
        /// The key could not be derived, or the random bytes had.
        case keyNotMade
    }

    /// The database's bytes; `random` gives the seeds and keys (the system's unless a test gives its own).
    public static func write(
        _ entries: [VaultEntry],
        password: String,
        now: Date,
        random: (Int) -> [UInt8] = Self.systemRandom
    ) throws(Failure) -> Data {
        let seed = random(32)
        let iv = random(12)
        let salt = random(32)
        let streamKey = random(64)
        guard seed.count == 32, iv.count == 12, salt.count == 32, streamKey.count == 64 else { throw .keyNotMade }
        let header = Self.header(seed: seed, iv: iv, salt: salt)

        let composite = [UInt8](SHA256.hash(data: [UInt8](SHA256.hash(data: Data(password.utf8)))))
        let transformed: [UInt8]
        do {
            let parameters = try Argon2.Parameters(
                variant: .id,
                memoryKiB: Int(memory / 1024),
                passes: Int(passes),
                lanes: Int(lanes),
                tagLength: 32
            )
            transformed = try Argon2.hash(password: composite, salt: salt, parameters: parameters, threads: Int(lanes))
        } catch {
            throw .keyNotMade
        }
        let master = [UInt8](SHA256.hash(data: seed + transformed))
        let macBase = [UInt8](SHA512.hash(data: seed + transformed + [1]))

        let hash = [UInt8](SHA256.hash(data: header))
        let headerMAC = KeePassFile.mac(index: .max, base: macBase, data: header, indexed: false)
        let streamHash = [UInt8](SHA512.hash(data: streamKey))
        guard var stream = ChaCha20(key: Array(streamHash[0 ..< 32]), nonce: Array(streamHash[32 ..< 44])),
            var cipher = ChaCha20(key: master, nonce: iv)
        else { throw .keyNotMade }
        var attachments: [Data] = []
        let xml = KeePassXMLWriter.xml(entries, now: now, attachments: &attachments, protect: { $0 = stream.apply($0) })
        var inner = field(1, le32(3)) + field(2, streamKey)
        for attachment in attachments { inner += field(3, [0] + [UInt8](attachment)) }
        inner += field(0, [])
        let encrypted = cipher.apply(inner + [UInt8](xml.utf8))

        var out = header + hash + Array(headerMAC)
        var index: UInt64 = 0
        var offset = 0
        // Blocks of 1 MiB, each with its HMAC; an empty block ends them.
        while true {
            let block = Array(encrypted[offset ..< min(offset + (1 << 20), encrypted.count)])
            let length = le32(UInt32(block.count))
            out += Array(KeePassFile.mac(index: index, base: macBase, data: length + block)) + length + block
            if block.isEmpty { break }
            offset += block.count
            index += 1
        }
        return Data(out)
    }

    public static func systemRandom(_ count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        guard unsafe SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else { return [] }
        return bytes
    }

    /// The outer header: version 4.0, ChaCha20, no compression, the seed, the IV and Argon2id's parameters.
    private static func header(seed: [UInt8], iv: [UInt8], salt: [UInt8]) -> [UInt8] {
        var kdf: [UInt8] = [0x00, 0x01]
        func item(_ type: UInt8, _ key: String, _ value: [UInt8]) {
            kdf += [type] + le32(UInt32(key.utf8.count)) + Array(key.utf8) + le32(UInt32(value.count)) + value
        }
        item(0x42, "$UUID", KeePassHeader.hex("9e298b1956db4773b23dfc3ec6f0a1e6"))
        item(0x05, "I", le64(passes))
        item(0x05, "M", le64(memory))
        item(0x04, "P", le32(lanes))
        item(0x42, "S", salt)
        item(0x04, "V", le32(0x13))
        kdf.append(0)
        var bytes = KeePassHeader.signature + [0, 0, 4, 0]
        bytes += field(2, KeePassHeader.hex("d6038a2b8b6f4cb5a524339a31dbb59a"))
        bytes += field(3, le32(0))
        bytes += field(4, seed)
        bytes += field(7, iv)
        bytes += field(11, kdf)
        bytes += field(0, [0x0D, 0x0A, 0x0D, 0x0A])
        return bytes
    }

    private static func field(_ id: UInt8, _ value: [UInt8]) -> [UInt8] {
        [id] + le32(UInt32(value.count)) + value
    }

    static func le32(_ value: UInt32) -> [UInt8] {
        (0 ..< 4).map { UInt8(truncatingIfNeeded: value >> (8 * $0)) }
    }

    static func le64(_ value: UInt64) -> [UInt8] {
        (0 ..< 8).map { UInt8(truncatingIfNeeded: value >> (8 * $0)) }
    }
}
