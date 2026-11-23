internal import CryptoKit
public import Foundation

extension BinaryDelta {
    /// The new file `delta` makes from `old`. Every number in it is checked before it is used: a delta that does not hold
    /// together throws, and the result is checked against the SHA-256 it names.
    public static func apply(_ delta: Data, to old: Data) throws(Failure) -> Data {
        let bytes = [UInt8](delta)
        let headerSize = magic.count + 64 + 32
        guard bytes.count >= magic.count, bytes.prefix(magic.count).elementsEqual(magic) else { throw .notADelta }
        guard bytes.count >= headerSize else { throw .malformed }
        guard bytes[magic.count ..< magic.count + 32].elementsEqual(SHA256.hash(data: old)) else { throw .otherOldFile }
        let wanted = bytes[magic.count + 32 ..< magic.count + 64]
        var numbers: [Int] = []
        for index in 0 ..< 4 { numbers.append(try number(in: bytes, at: magic.count + 64 + index * 8)) }
        let size = numbers[0]
        guard size >= 0, size <= largest, numbers[1...].allSatisfy({ $0 >= 0 }),
            numbers[1...].reduce(headerSize, { $0.addingReportingOverflow($1).partialValue }) == bytes.count
        else { throw .malformed }
        // Bound each block's decompressed size before allocating (controls ≤ 24 MiB, diff & extra ≤ new size, ADR-0125).
        let limits = [min(max(size, 1) * 24, 24 << 20), size, size]
        var start = headerSize
        var blocks: [[UInt8]] = []
        for (index, length) in numbers[1...].enumerated() {
            let slice = Data(bytes[start ..< start + length])
            blocks.append([UInt8](try decompress(slice, maxOutput: limits[index])))
            start += length
        }
        let new = try run(controls: blocks[0], difference: blocks[1], extra: blocks[2], old: [UInt8](old), size: size)
        guard SHA256.hash(data: new).elementsEqual(wanted) else { throw .wrongResult }
        return Data(new)
    }

    /// The new file from the decompressed blocks.
    private static func run(
        controls: [UInt8],
        difference: [UInt8],
        extra: [UInt8],
        old: [UInt8],
        size: Int
    ) throws(Failure) -> [UInt8] {
        guard controls.count % 24 == 0 else { throw .malformed }
        var new: [UInt8] = []
        new.reserveCapacity(size)
        var oldAt = 0
        var differenceAt = 0
        var extraAt = 0
        for at in stride(from: 0, to: controls.count, by: 24) {
            let add = try number(in: controls, at: at)
            let copy = try number(in: controls, at: at + 8)
            let seek = try number(in: controls, at: at + 16)
            guard add >= 0, copy >= 0, add <= size - new.count, add <= difference.count - differenceAt,
                add == 0 || (oldAt >= 0 && add <= old.count - oldAt)
            else { throw .malformed }
            for offset in 0 ..< add { new.append(old[oldAt + offset] &+ difference[differenceAt + offset]) }
            differenceAt += add
            oldAt += add
            guard copy <= size - new.count, copy <= extra.count - extraAt else { throw .malformed }
            new.append(contentsOf: extra[extraAt ..< extraAt + copy])
            extraAt += copy
            guard abs(seek) <= largest else { throw .malformed }
            oldAt += seek
        }
        guard new.count == size else { throw .malformed }
        return new
    }

    /// The little-endian 64-bit number at `at`.
    static func number(in bytes: [UInt8], at: Int) throws(Failure) -> Int {
        guard at >= 0, at + 8 <= bytes.count else { throw .malformed }
        var value: UInt64 = 0
        for index in (0 ..< 8).reversed() { value = value << 8 | UInt64(bytes[at + index]) }
        return Int(Int64(bitPattern: value))
    }
}
