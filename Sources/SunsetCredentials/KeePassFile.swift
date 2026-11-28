internal import AemiArgon2
import CommonCrypto
import CryptoKit
import Foundation

/// A KeePass database (KDBX 4, as KeePass 2 and KeePassXC write it) opened with its password and, if it has one, its key
/// file: the XML it holds and the files attached to its entries. Nothing of it is written to disk.
///
/// The format, as KeePass documents it (keepass.info/help/kb/kdbx.html, "KDBX 4"): the header is checked by its SHA-256
/// and its HMAC-SHA256; the composite key (SHA-256 of the password's and the key file's SHA-256s) is derived by AES-KDF or
/// Argon2 (d or id, version 1.3) with the header's parameters, which are the file's and so checked against bounds before
/// any derivation; the payload, in HMAC-SHA256 blocks each checked before use, is AES-256-CBC or ChaCha20 then gzip; an
/// inner header gives the stream that hides protected values (ChaCha20) and the attachments.
enum KeePassFile {
    enum Failure: Error, Equatable, Sendable {
        case notKeePass
        /// A KDBX of another major version (3 and older): KeePass and KeePassXC save it as 4.
        case unsupportedVersion(Int)
        case unsupportedCipher
        case unsupportedDerivation
        /// The derivation's parameters are beyond what a KeePass database uses: the file is refused, not derived.
        case derivationTooCostly
        /// The password, or the key file, is not this database's.
        case wrongKey
        case damaged
    }

    /// What the database holds: its XML and its attachments, in the inner header's order.
    struct Contents {
        let xml: Data
        let attachments: [Data]
        /// The stream that hides protected values, in document order.
        var protected: ChaCha20
    }

    /// Whether `data` starts as a KDBX file does.
    static func isKeePass(_ data: Data) -> Bool {
        data.prefix(8).elementsEqual(KeePassHeader.signature)
    }

    static func open(_ data: Data, password: String, keyFile: Data? = nil) throws(Failure) -> Contents {
        let file = [UInt8](data)
        let header = try KeePassHeader(file)
        var reader = ByteReader(Array(file[header.end...]))
        let hash = try reader.take(32)
        let mac = try reader.take(32)
        guard Array(SHA256.hash(data: header.bytes)) == hash else { throw .damaged }

        var parts = [UInt8](SHA256.hash(data: Data(password.utf8)))
        if let keyFile { parts += Self.keyFileKey(keyFile) }
        let composite = [UInt8](SHA256.hash(data: parts))
        let transformed = try derive(composite, header.derivation)
        let master = [UInt8](SHA256.hash(data: header.masterSeed + transformed))
        let macBase = [UInt8](SHA512.hash(data: header.masterSeed + transformed + [1]))
        guard Array(blockMAC(index: .max, base: macBase, data: header.bytes, indexed: false)) == mac else {
            throw .wrongKey
        }

        var encrypted: [UInt8] = []
        var index: UInt64 = 0
        while true {
            let blockMAC = try reader.take(32)
            let lengthBytes = try reader.take(4)
            let length = Int(lengthBytes.reversed().reduce(UInt32(0)) { $0 << 8 | UInt32($1) })
            let block = try reader.take(length)
            guard Array(Self.blockMAC(index: index, base: macBase, data: lengthBytes + block)) == blockMAC else {
                throw .damaged
            }
            if length == 0 { break }
            encrypted += block
            index += 1
        }
        var plain = try decrypt(encrypted, cipher: header.cipher, key: master, iv: header.iv)
        if header.gzip { plain = try Gunzip.inflate(plain) }
        return try inner(plain)
    }

    /// The key a key file gives (KeePass's rules): an XML key file's key, 32 raw bytes, 64 hex digits, else its SHA-256.
    static func keyFileKey(_ data: Data) -> [UInt8] {
        let bytes = [UInt8](data)
        let text = String(decoding: bytes, as: UTF8.self)
        if text.contains("<KeyFile"), let key = KeePassKeyFile.key(text) { return key }
        if bytes.count == 32 { return bytes }
        // As KeePass reads it: exactly 64 bytes, all hex digits (a line break after them makes it a file to hash).
        if bytes.count == 64, text.allSatisfy(\.isHexDigit) { return KeePassHeader.hex(text) }
        return [UInt8](SHA256.hash(data: bytes))
    }

    /// The bounds a derivation's parameters must keep: those KeePass and KeePassXC allow, well past their defaults.
    static let maxArgon2Memory: UInt64 = 2 << 30
    static let maxArgon2Iterations: UInt64 = 1000
    static let maxAESRounds: UInt64 = 200_000_000

    private static func derive(_ key: [UInt8], _ derivation: KeePassHeader.Derivation?) throws(Failure) -> [UInt8] {
        switch derivation {
            case .aes(let rounds, let seed)?:
                guard rounds >= 1, rounds <= maxAESRounds else { throw .derivationTooCostly }
                return try aesKDF(key, seed: seed, rounds: rounds)
            case .argon2(let id, let salt, let memory, let iterations, let lanes, let secret, let data)?:
                guard memory >= 8 << 10, memory <= maxArgon2Memory, (1 ... maxArgon2Iterations).contains(iterations),
                    (1 ... 64).contains(lanes)
                else { throw .derivationTooCostly }
                do {
                    let parameters = try Argon2.Parameters(
                        variant: id ? .id : .d,
                        memoryKiB: Int(memory / 1024),
                        passes: Int(iterations),
                        lanes: Int(lanes),
                        tagLength: 32
                    )
                    return try Argon2.hash(
                        password: key,
                        salt: salt,
                        secret: secret,
                        associatedData: data,
                        parameters: parameters,
                        threads: Int(lanes)
                    )
                } catch {
                    throw .unsupportedDerivation
                }
            case nil: throw .damaged
        }
    }

    /// AES-KDF: the key encrypted `rounds` times with AES-256 in ECB keyed by `seed`, then its SHA-256.
    private static func aesKDF(_ key: [UInt8], seed: [UInt8], rounds: UInt64) throws(Failure) -> [UInt8] {
        var cryptor: CCCryptorRef?
        let made = seed.withUnsafeBytes { seedBytes in
            unsafe CCCryptorCreate(
                CCOperation(kCCEncrypt),
                CCAlgorithm(kCCAlgorithmAES),
                CCOptions(kCCOptionECBMode),
                seedBytes.baseAddress,
                kCCKeySizeAES256,
                nil,
                &cryptor
            )
        }
        guard made == kCCSuccess, let cryptor else { throw .unsupportedDerivation }
        defer { unsafe CCCryptorRelease(cryptor) }
        var block = key
        var out = [UInt8](repeating: 0, count: 32)
        var moved = 0
        for _ in 0 ..< rounds {
            let status = unsafe CCCryptorUpdate(cryptor, block, 32, &out, 32, &moved)
            guard status == kCCSuccess else { throw .unsupportedDerivation }
            swap(&block, &out)
        }
        return [UInt8](SHA256.hash(data: block))
    }

    /// A block's HMAC-SHA256 over its index then its data, keyed by SHA-512 of its index and the HMAC base key; the
    /// header's (`indexed` false: over its bytes alone) has the largest index.
    private static func blockMAC(index: UInt64, base: [UInt8], data: [UInt8], indexed: Bool = true) -> HMAC<SHA256>.MAC
    {
        let indexBytes = (0 ..< 8).map { UInt8(truncatingIfNeeded: index >> (8 * $0)) }
        let key = SymmetricKey(data: Array(SHA512.hash(data: indexBytes + base)))
        return HMAC<SHA256>.authenticationCode(for: indexed ? indexBytes + data : data, using: key)
    }

    private static func decrypt(_ data: [UInt8], cipher: KeePassHeader.Cipher, key: [UInt8], iv: [UInt8])
        throws(Failure) -> [UInt8]
    {
        switch cipher {
            case .chaCha20:
                guard var stream = ChaCha20(key: key, nonce: iv) else { throw .damaged }
                return stream.apply(data)
            case .aes256:
                guard
                    let plain = BitwardenEncryptedExport.aes256CBCCrypt(
                        operation: CCOperation(kCCDecrypt),
                        key: SymmetricKey(data: key),
                        iv: Data(iv),
                        input: Data(data)
                    )
                else { throw .damaged }
                return [UInt8](plain)
        }
    }

    /// The inner header (its protected values' stream, its attachments), then the XML.
    private static func inner(_ plain: [UInt8]) throws(Failure) -> Contents {
        var reader = ByteReader(plain)
        var streamID: UInt32 = 0
        var streamKey: [UInt8] = []
        var attachments: [Data] = []
        while true {
            let id = try reader.take(1)[0]
            let length = Int(try reader.uint32())
            let value = try reader.take(length)
            switch id {
                case 0:
                    let rest = try reader.take(plain.count - reader.offset)
                    let hash = [UInt8](SHA512.hash(data: streamKey))
                    guard streamID == 3,
                        let stream = ChaCha20(key: Array(hash[0 ..< 32]), nonce: Array(hash[32 ..< 44]))
                    else { throw .unsupportedCipher }
                    return Contents(xml: Data(rest), attachments: attachments, protected: stream)
                case 1:
                    var value = ByteReader(value)
                    streamID = try value.uint32()
                case 2: streamKey = value
                case 3: attachments.append(Data(value.dropFirst()))
                default: continue
            }
        }
    }
}
