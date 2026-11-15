// Part of Scripts/lights-probe: records what windows opened after this tool show on a display, for some seconds, and keeps
// each frame in which a region changed. Every window open when it starts is left out of the picture, so nothing of the
// person's screen is recorded. Args: x y width height (global points of the region) seconds outdir.
import AppKit
import CoreImage
import ScreenCaptureKit

/// Keeps the frames in which the region changed, as pictures named by their order and time.
final class Sink: NSObject, SCStreamOutput, @unchecked Sendable {
    let crop: CGRect
    let folder: String
    let context = CIContext()
    var last: Data?
    var first: CMTime?
    var saved = 0
    var frames = 0

    init(crop: CGRect, folder: String) {
        self.crop = crop
        self.folder = folder
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let pixels = buffer.imageBuffer else { return }
        frames += 1
        let time = buffer.presentationTimeStamp
        let start = first ?? time
        first = start
        let image = CIImage(cvPixelBuffer: pixels)
        // CoreImage's origin is at the bottom left.
        let flipped = CGRect(x: crop.minX, y: image.extent.height - crop.maxY, width: crop.width, height: crop.height)
        guard let part = context.createCGImage(image.cropped(to: flipped), from: flipped) else { return }
        let picture = NSBitmapImageRep(cgImage: part)
        guard let bytes = picture.bitmapData else { return }
        let data = Data(bytes: bytes, count: picture.bytesPerRow * picture.pixelsHigh)
        guard data != last else { return }
        last = data
        let milliseconds = Int((time - start).seconds * 1000)
        let name = String(format: "%@/f%03d-%05dms.png", folder, saved, milliseconds)
        if let png = picture.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: name))
            saved += 1
        }
    }
}

let numbers = CommandLine.arguments.dropFirst().prefix(5).compactMap(Double.init)
guard numbers.count == 5, CommandLine.arguments.count > 6 else {
    print("usage: record x y width height seconds folder")
    exit(1)
}
let region = CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
let folder = CommandLine.arguments[6]
try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)

let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
let middle = CGPoint(x: region.midX, y: region.midY)
guard let display = content.displays.first(where: { $0.frame.contains(middle) }) else {
    print("no display at \(middle)")
    exit(1)
}
let scale = CGDisplayCopyDisplayMode(display.displayID).map { Double($0.pixelWidth) / Double($0.width) } ?? 2
let filter = SCContentFilter(display: display, excludingWindows: content.windows)
let configuration = SCStreamConfiguration()
configuration.width = Int(display.frame.width * scale)
configuration.height = Int(display.frame.height * scale)
configuration.minimumFrameInterval = CMTime(value: 1, timescale: 120)
configuration.pixelFormat = kCVPixelFormatType_32BGRA
configuration.showsCursor = false
configuration.queueDepth = 8
let crop = CGRect(
    x: (region.minX - display.frame.minX) * scale,
    y: (region.minY - display.frame.minY) * scale,
    width: region.width * scale,
    height: region.height * scale
)
let sink = Sink(crop: crop, folder: folder)
let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
try stream.addStreamOutput(sink, type: .screen, sampleHandlerQueue: DispatchQueue(label: "frames"))
try await stream.startCapture()
print("ready display \(Int(display.frame.width))x\(Int(display.frame.height)) scale \(scale)")
fflush(stdout)
try await Task.sleep(for: .seconds(numbers[4]))
try await stream.stopCapture()
print("frames \(sink.frames), kept \(sink.saved)")
