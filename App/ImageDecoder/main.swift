import Foundation
import SunsetRenderMac

/// App-Sandboxed, zero-network, zero-file-access XPC service (`studio.aemi.sunset.imagedecoder`, N-S5 / R-DES-2).
/// Decodes untrusted terminal Kitty PNG bytes via `ImageIODecoder` outside the main Sunset process that holds the
/// credential vault and terminal PTYs.
private final class ImageDecoderServiceDelegate: NSObject, NSXPCListenerDelegate, SunsetImageDecoderXPCProtocol {
    private let decoder = ImageIODecoder()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: (any SunsetImageDecoderXPCProtocol).self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func decodePNG(_ data: NSData, withReply reply: @escaping (Int, Int, NSData?) -> Void) {
        let bytes = [UInt8](data as Data)
        guard let decoded = decoder.decodePNG(bytes) else {
            reply(0, 0, nil)
            return
        }
        reply(decoded.width, decoded.height, Data(decoded.rgba) as NSData)
    }
}

private let delegate = ImageDecoderServiceDelegate()
private let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
