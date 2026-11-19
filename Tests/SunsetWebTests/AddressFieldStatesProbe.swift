import AppKit
import Foundation
import SunsetShell
import SunsetTestSupport
import SwiftUI
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Pictures of the sidebar's field in the owner's two screenshots' states (2026-11-19), to `SUNSET_ADDRESS_STATES`
/// (a folder): under the pointer; typed in; typed in after a change of width. A probe, never in the suite.
@MainActor @Suite("The address field's states (probe)")
struct AddressFieldStatesProbe {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_ADDRESS_STATES"] != nil))
    func `pictures of each state`() async throws {
        let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SUNSET_ADDRESS_STATES"] ?? "/tmp")
        let long =
            "https://idmsa.apple.com/appleauth/auth/authorize/signin?frame_id=auth-0c5b1d7e"
            + "&language=en_US&iframeId=auth-0c5b1d7e&client_id=a0110d07f757&rv=1"
        for (name, hovering) in [("hovering", true), ("typed", false)] {
            let page = WebContent(url: URL(string: long), settings: WebSettings(applicationName: "x"))
            let window = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 183, height: 46),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            defer { window.close() }
            let host = NSHostingView(
                rootView: AnyView(
                    Self.sidebar(AddressField(content: page, reload: true, hovering: hovering))
                        .frame(width: 167, height: 30).padding(8)
                )
            )
            window.contentView = host
            window.appearance = NSAppearance(named: .darkAqua)
            window.makeKeyAndOrderFront(nil)
            await RealWait.pass(.milliseconds(300))
            if !hovering { page.wantsAddress = true }
            await RealWait.pass(.milliseconds(400))
            Self.picture(host, to: folder.appending(path: "address-\(name).png"))
            if !hovering, let field = Self.field(in: host), let editor = field.currentEditor() as? NSTextView {
                // As the person pressing the right arrow: the caret at the end.
                editor.moveToEndOfDocument(nil)
                await RealWait.pass(.milliseconds(300))
                Self.picture(host, to: folder.appending(path: "address-typed-end.png"))
            }
            if !hovering {
                window.setContentSize(CGSize(width: 220, height: 46))
                host.rootView = AnyView(
                    Self.sidebar(AddressField(content: page, reload: true)).frame(width: 204, height: 30).padding(8)
                )
                await RealWait.pass(.milliseconds(400))
                Self.picture(host, to: folder.appending(path: "address-typed-wider.png"))
            }
        }
    }

    /// As the sidebar gives its field: a tab's corner, padding and height.
    private static func sidebar(_ field: AddressField) -> some View {
        field.environment(\.controlRadius, 8).environment(\.controlPadding, 8).environment(\.controlHeight, 32)
    }

    private static func field(in view: NSView) -> AddressNSField? {
        if let field = view as? AddressNSField { return field }
        for child in view.subviews { if let found = field(in: child) { return found } }
        return nil
    }

    /// The layers drawn into a bitmap at 2×: SwiftUI's own layers too, which `cacheDisplay` leaves out.
    private static func picture(_ view: NSView, to url: URL) {
        view.wantsLayer = true
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        guard let layer = view.layer,
            let context = CGContext(
                data: nil,
                width: Int(view.bounds.width * 2),
                height: Int(view.bounds.height * 2),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return }
        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: 2, y: -2)
        layer.render(in: context)
        guard let image = context.makeImage() else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }
}
