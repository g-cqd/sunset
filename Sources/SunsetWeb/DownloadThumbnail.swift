import QuickLookThumbnailing
import SwiftUI

/// The Quick Look picture of a downloaded file (its icon while it is not finished).
struct DownloadThumbnail: View {
    let item: DownloadItem
    let size: Double
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "doc").font(.system(size: size * 0.5)).foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .task(id: item.state) { await load() }
    }

    private func load() async {
        guard let file = item.state == .finished ? item.destination : nil else {
            image = item.destination.map { NSWorkspace.shared.icon(forFile: $0.path) }
            return
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: file,
            size: CGSize(width: size, height: size),
            scale: scale,
            representationTypes: .all
        )
        let made = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        image = made?.nsImage ?? NSWorkspace.shared.icon(forFile: file.path)
    }
}
