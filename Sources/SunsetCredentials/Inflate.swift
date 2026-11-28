import Compression

/// DEFLATE (RFC 1951) undone, for gzip (`Gunzip`) and zip (`ZipReader`) members.
enum Inflate {
    /// A raw DEFLATE stream inflated, in steps; past `largest` bytes it is refused (a small file inflating without end).
    static func raw(_ input: [UInt8], largest: Int) throws(KeePassFile.Failure) -> [UInt8] {
        let stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { unsafe stream.deallocate() }
        guard
            unsafe compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK
        else { throw .damaged }
        defer { unsafe compression_stream_destroy(stream) }
        let chunk = 1 << 16
        var output: [UInt8] = []
        var buffer = [UInt8](repeating: 0, count: chunk)
        return try input.withUnsafeBufferPointer { source throws(KeePassFile.Failure) -> [UInt8] in
            unsafe stream.pointee.src_ptr = source.baseAddress.unsafelyUnwrapped
            unsafe stream.pointee.src_size = source.count
            while true {
                let status = buffer.withUnsafeMutableBufferPointer { target in
                    unsafe stream.pointee.dst_ptr = target.baseAddress.unsafelyUnwrapped
                    unsafe stream.pointee.dst_size = chunk
                    return unsafe compression_stream_process(stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                }
                let left = unsafe stream.pointee.dst_size
                let made = chunk - left
                output += buffer[0 ..< made]
                guard output.count <= largest else { throw .damaged }
                switch status {
                    case COMPRESSION_STATUS_END: return output
                    case COMPRESSION_STATUS_OK: continue
                    default: throw .damaged
                }
            }
        }
    }
}
