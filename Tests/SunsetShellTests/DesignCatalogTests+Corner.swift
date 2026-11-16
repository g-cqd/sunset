import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell

/// The button at the window's bottom corner as built (the owner's A1, 2026-11-15): the real face, pressed so that its shape
/// shows, in a corner of the window's radius, before (5 pt from the bottom, four corners of 5) and after.
extension DesignCatalogTests {
    private func corner(_ buttons: SidebarButtons, bottom: Double, named: SidebarButtonCorner?) -> some View {
        let window = UnevenRoundedRectangle(bottomTrailingRadius: buttons.windowRadius, style: .continuous)
        return SidebarIconButtonFace(
            label: Image(systemName: "books.vertical").font(Design.Text.small),
            pressed: true,
            metrics: buttons.metrics
        )
        .environment(\.sidebarButtonCorner, named)
        .padding(.trailing, buttons.margin + buttons.gap)
        .padding(.bottom, bottom)
        .frame(width: 64, height: 52, alignment: .bottomTrailing)
        .background(Color(white: 0.125), in: window)
        .environment(\.colorScheme, .dark)
    }

    @Test func `the button at the window's corner as built, drawn for the owner`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let buttons = SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil)
        let before = buttons.margin + buttons.header.dockedButtonInset
        let both = HStack(spacing: 8) {
            corner(buttons, bottom: before, named: nil)
            corner(buttons, bottom: buttons.bottom, named: .bottomTrailing)
        }
        .padding(8).background(Color(white: 0.5))
        let renderer = ImageRenderer(content: both)
        renderer.scale = 12
        let image = NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
        let data = try #require(image.representation(using: .png, properties: [:]))
        try data.write(to: folder.appending(path: "library-corner-built.png"))
    }
}
