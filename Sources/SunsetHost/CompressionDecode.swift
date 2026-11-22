internal import Compression

/// Decoding with Apple's Compression into a buffer of `capacity` bytes, returned cut to what was written. The call returns
/// the buffer's size when the data does not fit (it cuts it off), which cannot be told from an exact fit: callers ask one
/// byte more than they accept.
enum CompressionDecode {
    static func decode(_ source: ArraySlice<UInt8>, capacity: Int, _ algorithm: compression_algorithm) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: capacity)
        let written = out.withUnsafeMutableBufferPointer { target -> Int in
            source.withUnsafeBufferPointer { from -> Int in
                guard let to = target.baseAddress, let base = from.baseAddress else { return 0 }
                return compression_decode_buffer(to, target.count, base, from.count, nil, algorithm)
            }
        }
        out.removeSubrange(written...)
        return out
    }
}
