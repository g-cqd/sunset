import CoreImage
@preconcurrency import ScreenCaptureKit

/// What the person picked in macOS's picker, captured (ADR-0085): its last complete frame kept, at most 1920 wide and 30 a
/// second, handed to the page as a tab's frames are.
final class ScreenStream: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var latest: CVPixelBuffer?
    private var fresh = false
    private var ended = false
    private var stream: SCStream?
    private static let images = CIContext()
    private static let widest = 1920.0

    /// Starts capturing `filter`; false when the capture could not start.
    @MainActor func start(_ filter: SCContentFilter) async -> Bool {
        let configuration = SCStreamConfiguration()
        let scale = Double(filter.pointPixelScale)
        let width = filter.contentRect.width * scale
        let height = filter.contentRect.height * scale
        let shrink = min(1, Self.widest / max(width, 1))
        configuration.width = max(2, Int(width * shrink))
        configuration.height = max(2, Int(height * shrink))
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        do {
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: nil)  // ScreenCaptureKit's own queue
            try await stream.startCapture()
        } catch {
            return false
        }
        lock.withLock { self.stream = stream }
        return true
    }

    /// Whether it still captures.
    var isRunning: Bool {
        lock.withLock { !ended }
    }

    /// The newest frame not given yet; nil when nothing changed since the last one.
    func nextImage() -> CGImage? {
        let buffer: CVPixelBuffer? = lock.withLock {
            guard fresh else { return nil }
            fresh = false
            return latest
        }
        guard let buffer else { return nil }
        let image = CIImage(cvPixelBuffer: buffer)
        return Self.images.createCGImage(image, from: image.extent)
    }

    func stop() {
        let stream: SCStream? = lock.withLock {
            ended = true
            defer { self.stream = nil }
            return self.stream
        }
        stream?.stopCapture { _ in }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, buffer.isValid, let pixels = buffer.imageBuffer, Self.isComplete(buffer) else { return }
        lock.withLock {
            latest = pixels
            fresh = true
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        lock.withLock { ended = true }
    }

    /// A frame with new pixels (an idle or a blank one carries none).
    private static func isComplete(_ buffer: CMSampleBuffer) -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: false)
                as? [[SCStreamFrameInfo: Any]],
            let raw = attachments.first?[.status] as? Int
        else { return false }
        return SCFrameStatus(rawValue: raw) == .complete
    }
}
