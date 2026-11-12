import SwiftUI

/// The list of downloads, latest first, with Clear (web step f).
struct DownloadsList: View {
    let center: DownloadCenter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Downloads").font(.headline)
                Spacer()
                Button("Clear") { center.clear() }
                    .buttonStyle(.borderless)
                    .disabled(center.items.allSatisfy { $0.state == .running })
            }
            if center.items.isEmpty {
                Text("Nothing downloaded").foregroundStyle(.secondary).padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(center.items) { item in DownloadRow(item: item, center: center) }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
