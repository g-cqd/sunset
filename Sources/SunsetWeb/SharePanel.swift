import SunsetShell
import SwiftUI

/// The sheet a page's request to share its screen shows first (ADR-0082): Sunset's tabs, by Space, then "Screen, Window or
/// App…", macOS's own picker. Nothing is shared until one is chosen; Escape shares nothing.
struct SharePanel: View {
    let request: ShareRequest
    let host: String
    @State private var chosen: UUID?
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        ZStack {
            Color.black.opacity(Design.Fill.veil).contentShape(.rect).onTapGesture {}
            VStack(alignment: .leading, spacing: Design.Space.l) {
                Text.sentence("\(host) wants to see a tab or your screen", code: [host])
                    .font(Design.Text.body.weight(.semibold))
                if request.sources.isEmpty {
                    Text("No tab can be shared now.").foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Design.Space.m) {
                            ForEach(spaces, id: \.self) { space in
                                VStack(alignment: .leading, spacing: Design.Space.xs) {
                                    Text(space).font(Design.Text.detail).foregroundStyle(.secondary)
                                    ForEach(request.sources.filter { $0.space == space }) { source in row(source) }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding(Design.Space.xl)
            .frame(width: Design.Width.panel, alignment: .leading)
            .surface(surface.panelShape, shadow: .popover)
            .padding(Design.Space.l)
        }
    }

    private var spaces: [String] {
        var seen: Set<String> = []
        return request.sources.map(\.space).filter { seen.insert($0).inserted }
    }

    private func row(_ source: ShareSource) -> some View {
        Button {
            chosen = source.id
        } label: {
            HStack(spacing: Design.Space.s) {
                Image(systemName: chosen == source.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(chosen == source.id ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                Text(source.label).lineLimit(1)
                if let host = source.host {
                    Text(host).code().font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share \(source.label)")
    }
}
