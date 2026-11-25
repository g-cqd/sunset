public import Foundation

/// Objective-C XPC protocol between Sunset and its App-Sandboxed, zero-network image decoder XPC service
/// (`studio.aemi.sunset.imagedecoder`, N-S5 / R-DES-2).
@objc public protocol SunsetImageDecoderXPCProtocol {
    func decodePNG(_ data: NSData, withReply reply: @escaping (Int, Int, NSData?) -> Void)
}
