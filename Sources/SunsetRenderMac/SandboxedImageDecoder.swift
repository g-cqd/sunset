import Dispatch
public import Foundation
public import SunsetRender
import Synchronization

/// Objective-C XPC protocol between Sunset and its App-Sandboxed, zero-network image decoder XPC service
/// (`studio.aemi.sunset.imagedecoder`, N-S5 / R-DES-2).
@objc public protocol SunsetImageDecoderXPCProtocol {
    func decodePNG(_ data: NSData, withReply reply: @escaping (Int, Int, NSData?) -> Void)
}

/// Decodes untrusted terminal Kitty PNG images inside the embedded App-Sandboxed, zero-network XPC service
/// (`studio.aemi.sunset.imagedecoder` / `studio.aemi.sunset.dev.imagedecoder`) when running from a bundled `Sunset.app`.
/// Falls back to in-process `ImageIODecoder` only in bare CLI / SwiftPM test binaries where no XPCServices bundle exists.
public struct SandboxedImageDecoder: ImageDecoding, Sendable {
    /// Maximum accepted PNG payload size forwarded over XPC (64 MiB).
    public static let maximumPayloadBytes = 64 << 20
    /// Hard wall-clock timeout waiting for one XPC decode reply so a stalled decoder never blocks rendering.
    public static let decodeTimeoutSeconds: TimeInterval = 5.0

    private let serviceName: String?
    private let fallback = ImageIODecoder()

    public init(serviceName: String? = Self.bundledServiceName()) {
        self.serviceName = serviceName
    }

    /// Resolves the embedded image-decoder XPC service name if `Bundle.main` ships it under `Contents/XPCServices/`.
    public static func bundledServiceName(in bundle: Bundle = .main) -> String? {
        guard let appID = bundle.bundleIdentifier else { return nil }
        let xpcDir = bundle.bundleURL.appending(path: "Contents/XPCServices", directoryHint: .isDirectory)
        let xpcBundle = xpcDir.appending(path: "SunsetImageDecoder.xpc", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: xpcBundle.path) else { return nil }
        return "\(appID).imagedecoder"
    }

    public func decodePNG(_ file: [UInt8]) -> DecodedImage? {
        guard !file.isEmpty, file.count <= Self.maximumPayloadBytes else { return nil }
        guard let serviceName else { return fallback.decodePNG(file) }
        return decodeViaXPC(file, serviceName: serviceName)
    }

    /// Validates reply dimensions and RGBA byte length returned by the out-of-process decoder before accepting pixels.
    package static func validatedReply(width: Int, height: Int, rgba: Data?) -> DecodedImage? {
        guard width > 0, height > 0, let rgba else { return nil }
        let (pixels, pOverflow) = width.multipliedReportingOverflow(by: height)
        guard !pOverflow, pixels <= (1 << 24) else { return nil }
        let (byteCount, bOverflow) = pixels.multipliedReportingOverflow(by: 4)
        guard !bOverflow, rgba.count == byteCount else { return nil }
        return DecodedImage(width: width, height: height, rgba: [UInt8](rgba))
    }

    private func decodeViaXPC(_ file: [UInt8], serviceName: String) -> DecodedImage? {
        let connection = NSXPCConnection(serviceName: serviceName)
        connection.remoteObjectInterface = NSXPCInterface(with: (any SunsetImageDecoderXPCProtocol).self)
        connection.resume()
        defer { connection.invalidate() }

        let semaphore = DispatchSemaphore(value: 0)
        let result = Mutex<DecodedImage?>(nil)

        let proxy =
            connection.remoteObjectProxyWithErrorHandler { _ in
                semaphore.signal()
            } as? any SunsetImageDecoderXPCProtocol

        guard let proxy else { return nil }
        proxy.decodePNG(Data(file) as NSData) { width, height, rgbaData in
            if let decoded = Self.validatedReply(width: width, height: height, rgba: rgbaData as Data?) {
                result.withLock { $0 = decoded }
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + Self.decodeTimeoutSeconds)
        return result.withLock { $0 }
    }
}
