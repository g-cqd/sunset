internal import AppKit
internal import MarkdownLookKit
internal import SunsetDocuments
internal import SwiftUI

/// What a merge shows in one source editor (roadmap 0023 step M-e): the blocks of a conflict tinted where they stand, a card
/// under each with what the disk says and the answers, and for a moment the blocks a merge just put in.
///
/// The editor is the kit's text view; nothing of it is replaced. The tints are the layout's temporary attributes (they are
/// not the text's, and are not saved or undone). The text makes room for a card: the text container is given a path to keep
/// clear, as wide as the text, just under the block. The card is put there in the scroll view's clip view, beside the text
/// view, so that it scrolls with the text; and the scroll view is told the cards are among its children for accessibility,
/// which neither a text view nor a scroll view tells of views put in them (seen 2026-11-16: the buttons were not found).
@MainActor
final class SourceMarks {
    private let content: DocumentContent
    private weak var view: NSTextView?
    private var hosts: [Int: NSHostingController<ConflictCard>] = [:]
    private var order: [Int] = []
    private var laidOut: Layout?
    private var frameObserver: (any NSObjectProtocol)?
    /// What the scroll view tells accessibility it holds by itself (the text, the scrollers), read before cards are added.
    private var ownChildren: [Any]?
    /// The blocks a merge just put in, tinted while they are shown.
    var merged: [Range<Int>] = []

    /// What the cards were last placed for: placed again only when one of these changes.
    private struct Layout: Equatable {
        var conflicts: [DocumentConflict]
        var revision: Int
        var width: CGFloat
        var fontSize: Double
    }

    /// Between the text and a card, above and below.
    private static let gap: CGFloat = 4

    init(content: DocumentContent) { self.content = content }

    /// The cards, in the order of the text.
    var cards: [NSView] { order.compactMap { hosts[$0]?.view } }
    var isAttached: Bool { view != nil }

    /// Takes `view` as the editor to mark; nil (the editor is going) takes every mark off the one it had.
    func attach(to view: NSTextView?) {
        guard view !== self.view else { return }
        clear()
        if let frameObserver { NotificationCenter.default.removeObserver(frameObserver) }
        frameObserver = nil
        self.view = view
        guard let view else { return }
        view.postsFrameChangedNotifications = true
        frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: view,
            queue: nil
        ) { [weak self] _ in
            // Posted on the main thread, where views are.
            MainActor.assumeIsolated { self?.update() }
        }
    }

    /// Tints and cards as the document's conflicts are now.
    func update() {
        guard let view, let layout = unsafe view.layoutManager, let container = view.textContainer else { return }
        let length = view.textStorage?.length ?? 0
        let conflicts = content.document.conflicts
        layout.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: length))
        for range in merged { tint(range, ConflictTint.merged, in: layout, length: length) }
        for conflict in conflicts { tint(conflict.range, ConflictTint.mine, in: layout, length: length) }
        let padding = container.lineFragmentPadding
        let width = max(view.bounds.width - 2 * (view.textContainerInset.width + padding), 120)
        let wanted = Layout(
            conflicts: conflicts,
            revision: content.document.source.revision,
            width: width,
            fontSize: content.fontSize
        )
        guard wanted != laidOut else { return }
        laidOut = wanted
        for (id, host) in hosts where !conflicts.contains(where: { $0.id == id }) {
            host.view.removeFromSuperview()
            hosts[id] = nil
        }
        order = conflicts.map(\.id)
        // From the top: where a card goes depends on the cards above it, never on the ones below.
        var clear: [NSBezierPath] = []
        container.exclusionPaths = []
        for conflict in conflicts {
            let card = ConflictCard(content: content, conflict: conflict)
            let host = hosts[conflict.id] ?? NSHostingController(rootView: card)
            host.rootView = card
            hosts[conflict.id] = host
            let height = ceil(host.sizeThatFits(in: CGSize(width: width, height: 100_000)).height)
            let top = Self.bottom(of: conflict.range, in: layout, length: length)
            clear.append(NSBezierPath(rect: NSRect(x: 0, y: top, width: 100_000, height: height + 2 * Self.gap)))
            container.exclusionPaths = clear
            let origin = view.textContainerOrigin
            let frame = NSRect(x: origin.x + padding, y: origin.y + top + Self.gap, width: width, height: height)
            let holder = Self.holder(of: view)
            host.view.frame = holder === view ? frame : holder.convert(frame, from: view)
            if host.view.superview !== holder { holder.addSubview(host.view) }
        }
        tellAccessibility(of: view)
    }

    private func tellAccessibility(of view: NSTextView) {
        guard let scroll = view.enclosingScrollView else { return }
        if cards.isEmpty {
            if ownChildren != nil { scroll.setAccessibilityChildren(nil) }
            ownChildren = nil
        } else {
            let own = ownChildren ?? scroll.accessibilityChildren() ?? []
            ownChildren = own
            scroll.setAccessibilityChildren(own + cards)
        }
    }

    /// Scrolls the editor to the conflict the pane is on.
    func reveal() {
        guard let view, let conflict = content.document.conflicts.first(where: { $0.id == content.shownConflict })
        else { return }
        let length = view.textStorage?.length ?? 0
        let low = min(conflict.range.lowerBound, length)
        view.scrollRangeToVisible(NSRange(location: low, length: min(conflict.range.upperBound, length) - low))
        if let card = hosts[conflict.id]?.view { view.scrollToVisible(view.convert(card.bounds, from: card)) }
    }

    /// Where the cards are put: the clip view the text view scrolls in, else (a text view alone) the text view.
    static func holder(of view: NSTextView) -> NSView {
        if let clip = view.superview as? NSClipView { clip } else { view }
    }

    private func clear() {
        for host in hosts.values { host.view.removeFromSuperview() }
        hosts = [:]
        order = []
        laidOut = nil
        if let view { tellAccessibility(of: view) }
        guard let view, let layout = unsafe view.layoutManager else { return }
        let length = view.textStorage?.length ?? 0
        layout.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: length))
        if view.textContainer?.exclusionPaths.isEmpty == false { view.textContainer?.exclusionPaths = [] }
    }

    /// Tints the lines of text of `range`: not the blank lines that end a block.
    private func tint(_ range: Range<Int>, _ color: NSColor, in layout: NSLayoutManager, length: Int) {
        let low = min(range.lowerBound, length)
        var high = min(range.upperBound, length)
        if let text = layout.textStorage?.string as NSString? {
            while high > low + 1, [10, 13].contains(text.character(at: high - 1)),
                [10, 13].contains(text.character(at: high - 2))
            { high -= 1 }
        }
        guard high > low else { return }
        layout.addTemporaryAttribute(
            .backgroundColor,
            value: color,
            forCharacterRange: NSRange(location: low, length: high - low)
        )
    }

    /// The bottom of the last line of text of `range` (the blank lines that end a block are after the card); for blocks
    /// removed here, the bottom of the line before where they were.
    private static func bottom(of range: Range<Int>, in layout: NSLayoutManager, length: Int) -> CGFloat {
        guard length > 0, let text = layout.textStorage?.string as NSString? else { return 0 }
        var index = min(range.upperBound, length) - 1
        guard index >= 0 else { return 0 }
        while index > range.lowerBound, [10, 13].contains(text.character(at: index)) { index -= 1 }
        let glyph = layout.glyphIndexForCharacter(at: index)
        return layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil).maxY
    }
}
