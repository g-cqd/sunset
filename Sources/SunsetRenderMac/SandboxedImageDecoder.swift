public import Foundation
public import SunsetRender

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

        let gate = ReplyGate()
        let proxy =
            connection.remoteObjectProxyWithErrorHandler { _ in
                gate.finish(nil)
            } as? any SunsetImageDecoderXPCProtocol

        guard let proxy else { return nil }
        proxy.decodePNG(Data(file) as NSData) { width, height, rgbaData in
            gate.finish(Self.validatedReply(width: width, height: height, rgba: rgbaData as Data?))
        }
        return gate.wait(seconds: Self.decodeTimeoutSeconds)
    }

    private final class ReplyGate: @unchecked Sendable {
        private let condition = NSCondition()
        private var done = false
        private var decoded: DecodedImage?

        func finish(_ value: DecodedImage?) {
            condition.lock()
            if !done {
                decoded = value
                done = true
                condition.signal()
            }
            condition.unlock()
        }

        func wait(seconds: TimeInterval) -> DecodedImage? {
            let deadline = Date(timeIntervalSinceNow: seconds)
            condition.lock()
            while !done, condition.wait(until: deadline) {}
            let value = decoded
            condition.unlock()
            return value
        }
    }
}
