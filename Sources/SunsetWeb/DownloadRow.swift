import AppKit
import SunsetShell
import SwiftUI

/// A download in the list: its picture, name, size and progress, and what can be done with it (Stop, Resume, Show in Finder, Remove).
struct DownloadRow: View {
    let item: DownloadItem
    let center: DownloadCenter

    var body: some View {
        HStack(spacing: 8) {
            DownloadThumbnail(item: item, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).lineLimit(1).truncationMode(.middle)
                if item.state == .running {
                    ProgressView(value: item.fraction ?? 0).progressViewStyle(.linear).controlSize(.mini)
                }
                Text(status).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            actions
        }
        .padding(.vertical, 4)
        .contextMenu {
            if item.state == .finished, let file = item.destination {
                Button("Open") { NSWorkspace.shared.open(file) }
                Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([file]) }
            }
            if let source = item.source {
                Button("Copy Address") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(source.absoluteString, forType: .string)
                }
            }
            Divider()
            Button("Remove from List") { center.remove(item) }
        }
    }

    @ViewBuilder private var actions: some View {
        switch item.state {
            case .running:
                button("stop.circle", "Stop") { center.stop(item) }
            case .paused:
                button("arrow.clockwise.circle", "Resume") { center.resume(item) }.disabled(!item.canResume)
            case .finished:
                button("magnifyingglass.circle", "Show in Finder") {
                    if let file = item.destination { NSWorkspace.shared.activateFileViewerSelecting([file]) }
                }
            case .failed:
                button("xmark.circle", "Remove") { center.remove(item) }
        }
    }

    private func button(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: Design.Symbol.bar)) }
            .buttonStyle(.borderless)
            .help(help)
    }

    private var status: String {
        let size = ByteCountFormatter.string(fromByteCount: item.received, countStyle: .file)
        let total = item.expected.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        switch item.state {
            case .running: return total.map { "\(size) of \($0)" } ?? size
            case .paused: return "Stopped at \(size)" + (total.map { " of \($0)" } ?? "")
            case .finished: return total ?? size
            case .failed: return item.failure ?? "Failed"
        }
    }
}
