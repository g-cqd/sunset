import SunsetPane

extension AppCommand {
    /// Every command, in the menus' order.
    package static let table: [Self] = [file, view, panes, spaces, history, places].joined(separator: "\n")
        .split(separator: "\n").compactMap { parse(String($0)) }

    /// One command a line, by menu: name | title | symbol | menu | key | scope | words. A key is written as the file
    /// writes it (`KeyChord(text:)`); a scope is a `Scopes.Scope`, "-" for always, "-bar" for always and not in the bar.
    private static let file = """
        newWindow | New Window | macwindow.badge.plus | File | cmd+n | - |
        newTab | New Tab | plus.square | File | cmd+t | - |
        newTabOfKind | New Tab of Kind\u{2026} | plus.square.on.square | File | shift+cmd+t | - | terminal page kind
        newPrivateWindow | New Private Window | hand.raised.square | File | shift+cmd+n | web | incognito
        newPrivateTab | New Private Tab | hand.raised | File | opt+shift+cmd+n | web | incognito
        newDocument | New Document | doc.badge.plus | File | | documents | markdown note
        openFile | Open File\u{2026} | folder | File | cmd+o | documents |
        closeTab | Close Tab | xmark.square | File | cmd+w | - |
        closeOtherTabs | Close Other Tabs | xmark.square.fill | File | opt+cmd+w | - |
        closeWindow | Close Window | xmark.rectangle | File | shift+cmd+w | - |
        print | Print\u{2026} | printer | File | cmd+p | web |
        importFromBrowser | Import from Another Browser\u{2026} | square.and.arrow.down | File | | web | bookmarks chrome firefox safari
        """

    private static let view = """
        commandBar | Command Bar | magnifyingglass | Edit | cmd+l | -bar |
        zoomIn | Zoom In | plus.magnifyingglass | View | cmd++ | - | bigger larger font
        zoomOut | Zoom Out | minus.magnifyingglass | View | cmd+- | - | smaller font
        actualSize | Actual Size | 1.magnifyingglass | View | cmd+0 | - | reset zoom font
        previousPrompt | Previous Prompt | arrow.up.to.line | View | cmd+up | terminal | command jump
        nextPrompt | Next Prompt | arrow.down.to.line | View | cmd+down | terminal | command jump
        """

    private static let panes = """
        splitRight | Split Right | rectangle.split.2x1 | Panes | cmd+d | - | vertical side
        splitDown | Split Down | rectangle.split.1x2 | Panes | shift+cmd+d | - | horizontal below
        nextPane | Next Pane | arrow.right.square | Panes | opt+cmd+] | - |
        previousPane | Previous Pane | arrow.left.square | Panes | opt+cmd+[ | - |
        movePaneToTab | Move Pane to Its Own Tab | rectangle.portrait.and.arrow.right | Panes | | - | separate
        renameTab | Rename Tab\u{2026} | pencil | Panes | | - | name title
        togglePinned | Pin or Unpin Tab | pin | Panes | | - |
        toggleFavorite | Add to or Remove from Favorites | star | Panes | | - | favourite keep
        """

    private static let spaces = """
        nextTab | Show Next Tab | chevron.right.square | Window | shift+cmd+] | - |
        previousTab | Show Previous Tab | chevron.left.square | Window | shift+cmd+[ | - |
        newSpace | New Space | square.stack.3d.up.badge.plus | Spaces | | - | workspace
        editSpace | Edit Space\u{2026} | square.and.pencil | Spaces | | - | workspace colour color
        deleteSpace | Delete Space\u{2026} | trash | Spaces | | - | remove workspace
        nextSpace | Show Next Space | arrow.right.circle | Spaces | opt+cmd+right | - | workspace
        previousSpace | Show Previous Space | arrow.left.circle | Spaces | opt+cmd+left | - | workspace
        moveTabToSpace | Move Tab to Space\u{2026} | arrow.right.to.line.square | Spaces | | - | send workspace
        """

    private static let history = """
        back | Back | chevron.backward | History | cmd+[ | web | page
        forward | Forward | chevron.forward | History | cmd+] | web | page
        reload | Reload Page | arrow.clockwise | History | cmd+r | web | refresh
        reloadWithoutCache | Reload Page Without Cache | arrow.clockwise.circle | History | shift+cmd+r | web | refresh hard
        forceReload | Force Reload Page | exclamationmark.arrow.circlepath | History | opt+cmd+r | web | refresh hung stuck
        toggleMute | Mute or Unmute Page | speaker.slash | History | | web | sound audio
        stop | Stop Loading | xmark | History | cmd+. | web |
        openAddress | Open Address | link | History | | web | url location
        toggleInspector | Show or Hide Web Inspector | hammer | History | opt+cmd+i | web | developer devtools console
        """

    private static let places = """
        library | Library | books.vertical | Sidebar | | - |
        documents | Documents | doc.text | Library | | documents | files notes
        history | History | clock | Library | | web | visited
        downloads | Downloads | arrow.down.circle | Library | | web |
        passwords | Passwords | key | Library | | passwords | vault logins keys cards
        settings | Settings | gearshape | Sunset | cmd+, | - | preferences options configuration
        help | Sunset Help | questionmark.circle | Help | cmd+? | - | manual documentation shortcuts
        """

    /// A line of `rows`; nil when it is not one (`AppCommandTableTests` checks every command is there).
    private static func parse(_ line: String) -> Self? {
        let cells = line.split(separator: "|", omittingEmptySubsequences: false)
            .map { String($0.drop(while: \.isWhitespace).reversed().drop(while: \.isWhitespace).reversed()) }
        guard cells.count == 7, let id = ID(rawValue: cells[0]) else { return nil }
        let scope = Scopes.Scope(rawValue: cells[5])
        return Self(
            id,
            cells[1],
            cells[2],
            cells[3],
            key: KeyChord(text: cells[4]),
            scope: scope,
            words: cells[6].split(separator: " ").map(String.init),
            inBar: cells[5] != "-bar"
        )
    }
}
