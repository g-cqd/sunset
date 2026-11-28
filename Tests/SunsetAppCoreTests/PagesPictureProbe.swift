import AppKit
import Foundation
import SunsetPane
import SunsetShell
import SunsetTestSupport
import SwiftUI
import Testing

@testable import SunsetApp
@testable import SunsetCredentials

/// Pictures of the app's pages at several widths, in light and dark, written to `SUNSET_PAGES_PICTURES` (a folder): a
/// probe, never in the suite. Drawn in a window never shown.
@MainActor @Suite("The app's pages, pictured (probe)")
struct PagesPictureProbe {
    nonisolated private static let folder = ProcessInfo.processInfo.environment["SUNSET_PAGES_PICTURES"]

    @Test(.enabled(if: folder != nil))
    func `settings, help and passwords at three widths, light and dark`() async throws {
        let folder = try #require(Self.folder)
        let context = PaneViewContext(focused: true, translucent: false, optionAsMeta: false, backdrop: .black)
        let topics = (ProcessInfo.processInfo.environment["SUNSET_PAGES_TOPICS"] ?? "appearance.tint")
            .split(separator: ",").map(String.init)
        for width in [380.0, 720.0, 1180.0] {
            for dark in [false, true] {
                let scheme = dark ? "dark" : "light"
                for topic in topics {
                    let settings = SettingsContent(.settings(topic: topic))
                    try await picture(
                        SettingsPage(content: settings, context: context),
                        width,
                        dark,
                        "\(folder)/settings-\(topic)-\(Int(width))-\(scheme).png"
                    )
                }
                let help = HelpContent(.help(topic: "spaces"))
                try await picture(
                    HelpPage(content: help, context: context),
                    width,
                    dark,
                    "\(folder)/help-\(Int(width))-\(scheme).png"
                )
                var entry = EntryTemplate.login.makeEntry(title: "Example Mail")
                LoginImport.put("Username", "jane@example.com", in: &entry)
                LoginImport.put("Password", "correct horse battery", in: &entry)
                for editing in [false, true] {
                    let page = PasswordEntryPage(entry: entry, model: AppPasswords.model, editing: editing)
                    try await picture(
                        page,
                        width,
                        dark,
                        "\(folder)/entry-\(editing ? "edit" : "read")-\(Int(width))-\(scheme).png"
                    )
                }
                let passwords = PasswordsContent()
                try await picture(
                    PasswordsPage(content: passwords, context: context),
                    width,
                    dark,
                    "\(folder)/passwords-\(Int(width))-\(scheme).png"
                )
            }
        }
    }

    private func picture(_ view: some View, _ width: Double, _ dark: Bool, _ path: String) async throws {
        let size = CGSize(width: width, height: 760)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        defer { window.close() }
        let host = NSHostingView(
            rootView: view.frame(width: width, height: size.height)
                .background(dark ? Color.black : Color.white)
                .environment(\.colorScheme, dark ? .dark : .light)
        )
        host.frame = CGRect(origin: .zero, size: size)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        await RealWait.pass(.milliseconds(400))
        host.layoutSubtreeIfNeeded()
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        try #require(rep.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: path))
    }
}
