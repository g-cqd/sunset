import Compression
import Foundation

/// A gzip member's data, inflated (RFC 1952: its header, a DEFLATE stream, its trailer): a KeePass database's payload.
/// The inflated size is bounded: a small file inflating past it is refused, not followed.
enum Gunzip {
    /// The most bytes a database's XML may inflate to.
    static let largest = 512 << 20

    static func inflate(_ data: [UInt8]) throws(KeePassFile.Failure) -> [UInt8] {
        guard data.count >= 18, data[0] == 0x1F, data[1] == 0x8B, data[2] == 8 else { throw .damaged }
        let flags = data[3]
        var start = 10
        if flags & 4 != 0 {
            guard start + 2 <= data.count else { throw .damaged }
            start += 2 + Int(data[start]) | Int(data[start + 1]) << 8
        }
        for flag in [UInt8(8), 16] where flags & flag != 0 {
            guard let end = data[min(start, data.count)...].firstIndex(of: 0) else { throw .damaged }
            start = end + 1
        }
        if flags & 2 != 0 { start += 2 }
        guard start < data.count - 8 else { throw .damaged }
        return try raw(Array(data[start ..< data.count - 8]))
    }

    /// A raw DEFLATE stream inflated, in steps, up to `largest`.
    private static func raw(_ input: [UInt8]) throws(KeePassFile.Failure) -> [UInt8] {
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
