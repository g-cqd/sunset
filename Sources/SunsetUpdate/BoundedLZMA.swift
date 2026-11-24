internal import Compression
public import Foundation

/// Streaming LZMA compression and decompression with a hard output limit (ADR-0125), closing decompression-bomb attacks
/// where a small compressed payload expands to gigabytes before signature checks run.
public enum BoundedLZMA {
    public enum Failure: Error, Equatable {
        case malformed
        case outputLimitExceeded
    }

    /// Compresses `data` with LZMA; empty input yields empty output.
    public static func compress(_ data: Data) throws(Failure) -> Data {
        guard !data.isEmpty else { return Data() }
        return try process(data, operation: COMPRESSION_STREAM_ENCODE, maxOutput: data.count + 65_536)
    }

    /// Decompresses `data` with LZMA, aborting immediately if output exceeds `maxOutput` bytes.
    public static func decompress(_ data: Data, maxOutput: Int) throws(Failure) -> Data {
        guard !data.isEmpty else { return Data() }
        guard maxOutput >= 0 else { throw .outputLimitExceeded }
        return try process(data, operation: COMPRESSION_STREAM_DECODE, maxOutput: maxOutput)
    }

    private static func process(
        _ input: Data,
        operation: compression_stream_operation,
        maxOutput: Int
    ) throws(Failure) -> Data {
        let dummy = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        defer { unsafe dummy.deallocate() }
        var stream = unsafe compression_stream(
            dst_ptr: dummy,
            dst_size: 0,
            src_ptr: dummy,
            src_size: 0,
            state: nil
        )
        guard unsafe compression_stream_init(&stream, operation, COMPRESSION_LZMA) != COMPRESSION_STATUS_ERROR else {
            throw .malformed
        }
        defer { unsafe compression_stream_destroy(&stream) }

        let chunkSize = 65_536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer { unsafe buffer.deallocate() }
        var output = Data()
        let flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)

        // The closure does not throw: `Data.withUnsafeBytes` has a typed-throws form only in the newest SDKs (CI's runners lack it), so a
        // failure is kept and thrown once the closure is done.
        var failure: Failure?
        let result: Data? = input.withUnsafeBytes { raw -> Data? in
            guard let base = unsafe raw.bindMemory(to: UInt8.self).baseAddress else { return Data() }
            unsafe stream.src_ptr = base
            unsafe stream.src_size = raw.count
            while true {
                unsafe stream.dst_ptr = buffer
                unsafe stream.dst_size = chunkSize
                let status = unsafe compression_stream_process(&stream, flags)
                let produced = unsafe chunkSize - stream.dst_size
                if produced > 0 {
                    if output.count + produced > maxOutput {
                        failure = .outputLimitExceeded
                        return nil
                    }
                    unsafe output.append(buffer, count: produced)
                }
                switch status {
                    case COMPRESSION_STATUS_OK:
                        if produced == 0, unsafe stream.src_size == 0 {
                            failure = .malformed
                            return nil
                        }
                    case COMPRESSION_STATUS_END:
                        return output
                    default:
                        failure = .malformed
                        return nil
                }
            }
        }
        if let failure { throw failure }
        return result ?? Data()
    }
}
