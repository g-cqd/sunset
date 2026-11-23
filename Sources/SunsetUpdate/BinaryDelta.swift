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
    /// The largest new file a delta may say (256 MiB: a bound on what it makes us allocate, ADR-0125).
    static let largest = 256 << 20

    /// The delta that turns `old` into `new`. Strips any identical prefix and suffix first so re-signed binaries (e.g.
    /// 122 MB WebCore with only its header and signature changed) diff in milliseconds instead of sorting the whole file.
    public static func make(from old: Data, to new: Data) throws -> Data {
        let found = Self.scanWithEdgeSkip(old: [UInt8](old), new: [UInt8](new))
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

    /// Identical-edge skip + `DeltaScan` over only the differing middle, keeping memory and CPU proportional to what
    /// actually changed (ADR-0125).
    static func scanWithEdgeSkip(old: [UInt8], new: [UInt8]) -> DeltaScan.Found {
        let commonLimit = min(old.count, new.count)
        var prefix = 0
        while prefix < commonLimit, old[prefix] == new[prefix] { prefix += 1 }
        if prefix == old.count, prefix == new.count {
            var exact = DeltaScan.Found()
            if prefix > 0 {
                exact.controls.append(DeltaScan.Control(add: prefix, copy: 0, seek: 0))
                exact.difference = Array(repeating: 0, count: prefix)
            }
            return exact
        }
        var suffix = 0
        while suffix < commonLimit - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] {
            suffix += 1
        }
        // Fast path for in-place edits / re-signed Mach-O binaries (ADR-0125): when > 95% of bytes at identical
        // offsets in the common range already match, emit one direct diff control + tail copy in O(N) time and zero
        // suffix-array memory (re-signed 122 MB WebCore drops from ~52 s to ~0.2 s, same tiny LZMA output).
        if let direct = Self.directSameOffsetDiff(old: old, new: new, prefix: prefix) {
            return direct
        }
        // Only engage the edge skip when it saves meaningful work (> 4 KiB unchanged).
        guard prefix + suffix > 4096 else {
            return DeltaScan(old: old, new: new).run()
        }
        let midOld = Array(old[prefix ..< (old.count - suffix)])
        let midNew = Array(new[prefix ..< (new.count - suffix)])
        let middle = DeltaScan(old: midOld, new: midNew).run()
        var combined = DeltaScan.Found()
        if prefix > 0 {
            combined.controls.append(DeltaScan.Control(add: prefix, copy: 0, seek: 0))
            combined.difference.append(contentsOf: repeatElement(UInt8(0), count: prefix))
        }
        combined.controls.append(contentsOf: middle.controls)
        combined.difference.append(contentsOf: middle.difference)
        combined.extra.append(contentsOf: middle.extra)
        if suffix > 0 {
            // Re-align oldAt to the end of `midOld` (where `suffix` begins) after middle's controls.
            var oldAt = 0
            for control in middle.controls { oldAt += control.add + control.seek }
            let jump = midOld.count - oldAt
            combined.controls.append(DeltaScan.Control(add: 0, copy: 0, seek: jump))
            combined.controls.append(DeltaScan.Control(add: suffix, copy: 0, seek: 0))
            combined.difference.append(contentsOf: repeatElement(UInt8(0), count: suffix))
        }
        return combined
    }

    /// O(N) same-offset diff when > 95% of the overlapping region matches byte-for-byte (e.g. a re-signed Mach-O whose
    /// header and trailing `LC_CODE_SIGNATURE` changed while 99.8% of the binary is untouched).
    private static func directSameOffsetDiff(old: [UInt8], new: [UInt8], prefix: Int) -> DeltaScan.Found? {
        let common = min(old.count, new.count)
        guard common >= 65_536 else { return nil }
        // Sample 4096 evenly spaced offsets first (O(1) check) before scanning all bytes.
        let strideStep = max(1, (common - prefix) / 4096)
        var sampled = 0
        var matched = 0
        var probe = prefix
        while probe < common {
            sampled += 1
            if old[probe] == new[probe] { matched += 1 }
            probe += strideStep
        }
        guard sampled > 0, matched * 100 >= sampled * 95 else { return nil }
        var diff = [UInt8](repeating: 0, count: common)
        var exactMatches = prefix
        for index in prefix ..< common {
            let delta = new[index] &- old[index]
            diff[index] = delta
            if delta == 0 { exactMatches += 1 }
        }
        guard exactMatches * 100 >= common * 95 else { return nil }
        var found = DeltaScan.Found()
        let extraCount = max(0, new.count - common)
        found.controls.append(DeltaScan.Control(add: common, copy: extraCount, seek: 0))
        found.difference = diff
        if extraCount > 0 { found.extra = Array(new[common...]) }
        return found
    }

    /// LZMA via `BoundedLZMA` (native Compression framework).
    static func compress(_ data: Data) throws -> Data {
        try BoundedLZMA.compress(data)
    }

    /// Streaming bounded LZMA decompression; throws `malformed` on corrupt data or if output exceeds `maxOutput`.
    static func decompress(_ data: Data, maxOutput: Int) throws(Failure) -> Data {
        do { return try BoundedLZMA.decompress(data, maxOutput: maxOutput) } catch { throw .malformed }
    }
}

extension Data {
    mutating func append(littleEndian value: Int64) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: unsafe $0) }
    }
}
