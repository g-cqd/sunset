import AppKit
import SunsetRuntime
import UniformTypeIdentifiers

/// The picture of what is dropped on an entry's page: an image, or an image file.
@MainActor
enum QRDrop {
    static func images(_ providers: [NSItemProvider], read: @escaping @MainActor (CGImage) -> Void) {
        guard let provider = providers.first else { return }
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard let image = (object as? NSImage)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    return
                }
                Runtime.live.task { @MainActor in read(image) }
            }
        } else {
            _ = provider.loadObject(ofClass: NSURL.self) { object, _ in
                guard let url = object as? URL else { return }
                Runtime.live.task { @MainActor in
                    if let image = QRCodeImages.image(at: url) { read(image) }
                }
            }
        }
    }
}
