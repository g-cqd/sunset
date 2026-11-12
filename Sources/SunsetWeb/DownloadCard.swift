import SwiftUI

/// The latest download, shown while the pointer is on the downloads button: its Quick Look picture, name, size and progress.
struct DownloadCard: View {
    let item: DownloadItem

    var body: some View {
        HStack(spacing: 10) {
            DownloadThumbnail(item: item, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).lineLimit(2).truncationMode(.middle)
                if item.state == .running { ProgressView(value: item.fraction ?? 0).progressViewStyle(.linear) }
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 260, alignment: .leading)
    }

    private var detail: String {
        let size = ByteCountFormatter.string(fromByteCount: item.expected ?? item.received, countStyle: .file)
        return switch item.state {
            case .running: "Downloading, \(size)"
            case .paused: "Stopped"
            case .finished: size
            case .failed: item.failure ?? "Failed"
        }
    }
}
