internal import Compression
public import SunsetCore

/// Packs old history with LZFSE (Apple's Compression framework). Measured on 76 000 lines of coloured `git log -p` output plus source code in 120 columns,
/// chunks of 128 lines: 9.9 times smaller, 0.19 ms to pack a chunk and 0.02 ms to unpack it (LZ4: 4.5 times, 0.03 ms and 0.01 ms).
public struct LZFSEHistoryCodec: HistoryCodec {
    public init() {}

    public func pack(_ bytes: UnsafeRawBufferPointer) -> [UInt8]? {
        guard bytes.count > 1, let source = bytes.baseAddress else { return nil }
        // Room for one byte less than the input: the call returns 0 when the result does not fit, which is "not smaller".
        var out = [UInt8](repeating: 0, count: bytes.count - 1)
        let written = out.withUnsafeMutableBufferPointer { destination -> Int in
            guard let target = destination.baseAddress else { return 0 }
            return compression_encode_buffer(
                target,
                destination.count,
                source.assumingMemoryBound(to: UInt8.self),
                bytes.count,
                nil,
                COMPRESSION_LZFSE
            )
        }
        guard written > 0 else { return nil }
        // A new array of exactly this size: `removeLast` would keep the capacity of the buffer the result was made in (the size of the input).
        return Array(out.prefix(written))
    }

    public func unpack(_ packed: [UInt8], into output: UnsafeMutableRawBufferPointer) -> Bool {
        guard !packed.isEmpty, output.count > 0, let destination = output.baseAddress else { return false }
        // The call returns the size of the destination when the data does not fit (it cuts it off), which cannot be told from an exact fit: decode into one
        // byte more than expected and accept only the exact length.
        var scratch = [UInt8](repeating: 0, count: output.count + 1)
        let written = scratch.withUnsafeMutableBufferPointer { target -> Int in
            packed.withUnsafeBufferPointer { source -> Int in
                guard let to = target.baseAddress, let from = source.baseAddress else { return 0 }
                return compression_decode_buffer(to, target.count, from, source.count, nil, COMPRESSION_LZFSE)
            }
        }
        guard written == output.count else { return false }
        scratch.withUnsafeBytes { source in
            destination.copyMemory(from: source.baseAddress ?? UnsafeRawPointer(destination), byteCount: output.count)
        }
        return true
    }
}
