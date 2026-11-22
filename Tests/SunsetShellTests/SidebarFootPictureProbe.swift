import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Pictures of the sidebar's foot to `SUNSET_SIDEBAR_FOOT` (a folder): the Library's rail with downloads, and the
/// closed bar's edge (the downloads above the Library's glyph). A probe.
@MainActor @Suite("The sidebar's foot (probe)")
struct SidebarFootPictureProbe {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_SIDEBAR_FOOT"] != nil))
    func `pictures of the rail and the closed bar`() throws {
        let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SUNSET_SIDEBAR_FOOT"] ?? "/tmp")
        let buttons = SidebarButtons(layout: LayoutMetrics(), margin: 8, panelRadius: nil, windowRadius: 16)
        let downloads = AnyView(SidebarIconButton(symbol: "arrow.down.circle", help: "Downloads") {})
        let rail = SectionRail(
            selection: .history,
            buttons: buttons,
            leading: true,
            help: {},
            downloads: downloads
        ) { _ in }
        .frame(width: 40, height: 420)
        Self.picture(rail, size: CGSize(width: 40, height: 420), to: folder.appending(path: "rail-open.png"))
        let closed = VStack(spacing: buttons.layout.tabSpacing) {
            downloads
            SidebarIconButton(symbol: "books.vertical", help: "Library") {}
        }
        .environment(\.sidebarButtonMetrics, buttons.metrics)
        .frame(height: buttons.barHeight(rows: 2))
        .padding(8)
        Self.picture(
            closed,
            size: CGSize(width: 48, height: buttons.barHeight(rows: 2) + 16),
            to: folder.appending(path: "bar-closed.png")
        )
    }

    private static func picture(_ view: some View, size: CGSize, to url: URL) {
        let renderer = ImageRenderer(
            content: view.frame(width: size.width, height: size.height).background(Color(white: 0.15))
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 2
        guard let image = renderer.cgImage else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }
}
