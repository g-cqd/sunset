internal import CryptoKit
public import Foundation

/// Sunset's own binary delta between two versions of a file (roadmap 0122 C, ADR-0122), after Colin Percival's bsdiff:
/// the new file as runs "old bytes plus small differences" (which compress well: an executable's moved addresses), runs of
/// new bytes, and jumps in the old file. Three blocks, each compressed with LZMA (Apple's Compression framework), after a
/// header that names the old file and the new by their SHA-256.
///
/// Layout: `SSDELTA1`, the old file's SHA-256, the new file's, then four little-endian 64-bit numbers (the new file's
/// size, and the compressed sizes of the control, difference and extra blocks), then the three blocks. A control is three
/// 64-bit numbers: bytes to add to the old (from the difference block), bytes to copy (from the extra block), and how far
/// to move in the old file after.
public enum BinaryDelta {
    /// Why a delta was refused.
    public enum Failure: Error, Equatable {
        /// It does not start as a delta does.
        case notADelta
        /// It was made from another old file than the one given.
        case otherOldFile
        /// Its blocks or controls do not hold together (truncated, or out of the old file's or new file's bounds).
        case malformed
        /// What it makes is not the new file it names.
        case wrongResult
    }

    static let magic = Data("SSDELTA1".utf8)
    /// The largest new file a delta may say (a bound on what it makes us allocate).
    static let largest = 1 << 31

    /// The delta that turns `old` into `new`.
    public static func make(from old: Data, to new: Data) throws -> Data {
        let scan = DeltaScan(old: [UInt8](old), new: [UInt8](new))
        let found = scan.run()
        var controls = Data(capacity: found.controls.count * 24)
        for control in found.controls {
            for value in [control.add, control.copy, control.seek] { controls.append(littleEndian: Int64(value)) }
        }
        let blocks = try [controls, Data(found.difference), Data(found.extra)].map(compress)
        var delta = magic
        delta.append(contentsOf: SHA256.hash(data: old))
        delta.append(contentsOf: SHA256.hash(data: new))
        delta.append(littleEndian: Int64(new.count))
        for block in blocks { delta.append(littleEndian: Int64(block.count)) }
        for block in blocks { delta.append(block) }
        return delta
    }

    /// LZMA, or nothing for nothing.
    static func compress(_ data: Data) throws -> Data {
        data.isEmpty ? Data() : try (data as NSData).compressed(using: .lzma) as Data
    }

    /// The block back; throws `malformed` when it does not decompress.
    static func decompress(_ data: Data) throws(Failure) -> Data {
        guard !data.isEmpty else { return Data() }
        do { return try (data as NSData).decompressed(using: .lzma) as Data } catch { throw .malformed }
    }
}

extension Data {
    mutating func append(littleEndian value: Int64) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: unsafe $0) }
    }
}
