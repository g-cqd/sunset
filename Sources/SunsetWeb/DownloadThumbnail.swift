import QuickLookThumbnailing
import SunsetShell
import SwiftUI

/// The Quick Look picture of a downloaded file (its icon while it is not finished).
struct DownloadThumbnail: View {
    let item: DownloadItem
    let size: Double
    @State private var image: NSImage?
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "doc").font(.system(size: size * Design.Optical.thumbnailSymbol))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout), style: .continuous))
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
