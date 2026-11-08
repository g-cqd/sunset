@testable import SunsetCore

/// A codec that packs but cannot unpack, to see that a failure is a blank line and not a crash.
struct BrokenCodec: HistoryCodec {
    func pack(_ bytes: UnsafeRawBufferPointer) -> [UInt8]? { [0] }
    func unpack(_ packed: [UInt8], into output: UnsafeMutableRawBufferPointer) -> Bool { false }
}
