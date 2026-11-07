import AppKit
import SunsetConfig
import SunsetPrivate
import SwiftUI

/// What is behind the sidebar: a solid colour, a system material (`NSVisualEffectView`, `.sidebar`), Liquid Glass (`NSGlassEffectView`), or nothing, with the
/// shared tint over it and, when the sidebar has a blur radius of its own, a backdrop layer that blurs what is behind it by that radius (the window may be
/// blurred by another amount, or not at all).
struct SidebarBackdrop: NSViewRepresentable {
    var look: SidebarLook

    func makeNSView(context: Context) -> SidebarBackdropView { SidebarBackdropView() }

    func updateNSView(_ view: SidebarBackdropView, context: Context) { view.look = look }
}
