/// Every key the file can set, as dotted paths: what the reader accepts and the writer writes (a test keeps the three together). The keys of one section are
/// together, in the order the written file shows them: the writer opens a section once.
public enum ConfigurationKeys {
    /// The keys read and written by hand: what is not a plain value of an option (texts, colours that may be unset, lists,
    /// themes, the layout's measures); a plain value's key is its option's (`SettingCodec`).
    static let byHand: [String] = [
        "theme",
        "font.family",
        "font.boldFamily",
        "font.italicFamily",
        "font.boldItalicFamily",
        "font.features",
        "colors.foreground",
        "colors.background",
        "colors.cursor",
        "colors.ansi",
        "terminal.directory",
        "tabs.startAddress",
        "tabs.startFile",
        "tabs.startProfile",
        "sidebar.padding",
        "sidebar.enabled",
        "sidebar.autoHide",
        "sidebar.width",
        "layout.tabSpacing",
        "layout.tabSideInset",
        "layout.tabPaddingLeading",
        "layout.tabPaddingTrailing",
        "layout.tabPaddingVertical",
        "layout.tabRadius",
        "layout.closeButtonSize",
        "layout.closeButtonRadius",
        "layout.floatingTabSpacing",
        "layout.floatingTabSideInset",
        "layout.floatingTabPaddingLeading",
        "layout.floatingTabPaddingTrailing",
        "layout.floatingTabPaddingVertical",
        "layout.floatingTabRadius",
        "layout.floatingCloseButtonSize",
        "layout.floatingCloseButtonRadius",
        "layout.resizeHandleWidth",
        "layout.lightsInset",
        "layout.lightsGap",
        "layout.floatingLightsExtra",
        "layout.sidebarButtonSize",
        "layout.sidebarButtonRadius",
        "layout.hairlineWidth",
        "layout.hairlineOpacity",
        "layout.revealStripWidth",
        "layout.paneGap",
        "layout.innerCornerRadius",
        "layout.hideDelay",
        "layout.animation",
        "layout.terminalRadius",
        "layout.panelRadius",
        "appearance.tint.color",
        "appearance.tint.light",
        "scrollback.lines",
        "cursor.blinkTimeout",
        "features.terminal",
        "features.web",
        "features.documents",
        "features.credentials",
        "web.blockingLists",
        "web.proxy",
        "web.engine",
        "web.engines",
        "web.textOnlyZoom",
        "web.agent",
        "web.downloadFolder",
        "web.permissions.camera",
        "web.permissions.microphone",
        "web.permissions.screen",
        "web.permissions.location",
        "web.permissions.notifications",
        "web.permissions.popups",
        "web.permissions.autoplay"
    ]

    /// The file's sections, in the order the written file shows them.
    static let sections: [String] = [
        "theme", "font", "colors", "window", "terminal", "sidebar", "layout", "appearance", "tabs", "scroll",
        "scrollback", "cursor", "keyboard", "storage", "updates", "passwords", "documents", "spaces", "features", "web"
    ]

    /// Every key: the hand-written ones and the options' own, each section's together (its subsections too), the sections
    /// in their order.
    public static let all: [String] = grouped(byHand + SettingCodec.ordered)

    /// Keys no longer set (made fixed): read without a word, and taken out of the file when it is next saved (n115).
    public static let removed = ["window.decorations", "window.trafficLights"]

    /// `keys` with each section's (and subsection's) together, the sections first as `sections` orders them, then each part
    /// in the order its first key came.
    static func grouped(_ keys: [String]) -> [String] {
        final class Node {
            var order: [String] = []
            var children: [String: Node] = [:]
            var isKey = false
        }
        let root = Node()
        for key in keys {
            var node = root
            for part in key.split(separator: ".").map(String.init) {
                if node.children[part] == nil {
                    node.children[part] = Node()
                    node.order.append(part)
                }
                node = node.children[part] ?? node
            }
            node.isKey = true
        }
        root.order.sort { (sections.firstIndex(of: $0) ?? .max) < (sections.firstIndex(of: $1) ?? .max) }
        var out: [String] = []
        func walk(_ node: Node, _ prefix: String) {
            if node.isKey, !prefix.isEmpty {
                out.append(prefix)
            }
            for part in node.order {
                if let child = node.children[part] {
                    walk(child, prefix.isEmpty ? part : prefix + "." + part)
                }
            }
        }
        walk(root, "")
        return out
    }
}
