import SunsetShell
import SwiftUI

/// The sheet a page's request to share its screen shows first: Sunset's tabs, by Space, each as it looks now, then
/// "Screen, Window or App…", macOS's own picker (which shows its own previews). Nothing is shared until one is chosen;
/// Escape shares nothing.
struct SharePanel: View {
    let request: ShareRequest
    let host: String
    @State private var chosen: UUID?
    @State private var previews: [UUID: CGImage] = [:]
    @Environment(\.surfaceStyle) private var surface

    private let columns = [GridItem(.adaptive(minimum: Design.Size.shareCard), spacing: Design.Space.m)]

    var body: some View {
        PagePanel(width: Design.Width.sharePanel) {
            Text.sentence("\(host) wants to see a tab or your screen", code: [host])
                .font(Design.Text.body.weight(.semibold))
            if request.sources.isEmpty {
                Text("No tab can be shared now.").foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Design.Space.l) {
                        ForEach(spaces, id: \.self) { space in
                            VStack(alignment: .leading, spacing: Design.Space.s) {
                                Text(space).font(Design.Text.detail).foregroundStyle(.secondary)
                                LazyVGrid(columns: columns, alignment: .leading, spacing: Design.Space.m) {
                                    ForEach(request.sources.filter { $0.space == space }) { source in card(source) }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Design.Space.xs)
                }
                .bouncesOnlyWhenScrolling()
                .frame(maxHeight: Design.Size.dialogMessage * 2)
                .fixedSize(horizontal: false, vertical: true)
            }
            // macOS's own picker, under Sunset's tabs: a screen, a window, another app.
            Button {
                request.answer(.system)
            } label: {
                Label("Screen, Window or App\u{2026}", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Divider()
            HStack {
                Spacer()
                Button("Cancel") { request.answer(.cancel) }.keyboardShortcut(.cancelAction)
                Button("Share Tab") { if let chosen { request.answer(.tab(chosen)) } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(chosen == nil)
            }
        }
        .task { await takePreviews() }
    }

    private var spaces: [String] {
        var seen: Set<String> = []
        return request.sources.map(\.space).filter { seen.insert($0).inserted }
    }

    /// Each tab's picture, one after another (a page's snapshot waits for its next frame); a tab with none keeps its glyph.
    private func takePreviews() async {
        for source in request.sources where previews[source.id] == nil {
            if let image = await WebShare.preview(source.id) { previews[source.id] = image }
        }
    }

    private func card(_ source: ShareSource) -> some View {
        let isChosen = chosen == source.id
        return Button {
            chosen = source.id
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.xs) {
                preview(of: source)
                    .frame(maxWidth: .infinity)
                    .frame(height: Design.Size.shareCard * Design.Optical.sharePreviewRatio)
                    .clipShape(RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout), style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout), style: .continuous)
                            .strokeBorder(
                                isChosen ? AnyShapeStyle(.tint) : AnyShapeStyle(.separator),
                                lineWidth: isChosen ? 2 : 1
                            )
                    }
                Text(source.label).lineLimit(1).font(Design.Text.detail)
                Text(source.host ?? " ").code().font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share \(source.label)")
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    @ViewBuilder private func preview(of source: ShareSource) -> some View {
        if let image = previews[source.id] {
            Image(decorative: image, scale: 1).resizable().aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: source.host == nil ? "rectangle.on.rectangle" : "globe")
                    .font(
                        .system(
                            size: Design.Size.shareCard * Design.Optical.thumbnailSymbol
                                * Design.Optical.sharePreviewRatio
                        )
                    )
                    .foregroundStyle(.secondary)
            }
        }
    }
}
