package import SwiftUI

/// A button of the sidebar (the pin, the +, downloads): one rounded square, the sidebar's size and corner (`SidebarButtonMetrics`), that is both what
/// is drawn and what takes the click; the symbol secondary, primary with a light fill under the pointer, a darker one while pressed. A menu, when
/// given, opens on a right-click or a long press; the click is the action.
package struct SidebarIconButton<Content: View>: View {
    let help: String
    let action: () -> Void
    let label: Content
    var menu: AnyView?
    @Environment(\.sidebarButtonMetrics) private var metrics

    package init(help: String, menu: AnyView? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Content) {
        self.help = help
        self.menu = menu
        self.action = action
        self.label = label()
    }

    package var body: some View {
        Button(action: action) { label }
            .buttonStyle(SidebarIconButtonStyle(metrics: metrics))
            .help(help)
            .contextMenu { if let menu { menu } }
    }
}

extension SidebarIconButton where Content == SidebarSymbol {
    /// A button showing an SF Symbol, filled when `filled`.
    package init(symbol: String, filled: Bool = false, help: String, menu: AnyView? = nil, action: @escaping () -> Void)
    {
        self.init(help: help, menu: menu, action: action) { SidebarSymbol(name: symbol, filled: filled) }
    }
}
