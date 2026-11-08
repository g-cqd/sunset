@testable import SunsetCore

/// A codec that never gets anything smaller.
struct NoGainCodec: HistoryCodec {
    func pack(_ bytes: UnsafeRawBufferPointer) -> [UInt8]? { nil }
    func unpack(_ packed: [UInt8], into output: UnsafeMutableRawBufferPointer) -> Bool { false }
}
