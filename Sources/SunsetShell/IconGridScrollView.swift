import AppKit

/// The scroll view of the icon grid: the grid is as wide as it shows.
final class IconGridScrollView: NSScrollView {
    let grid = IconGridView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        documentView = grid
        hasVerticalScroller = true
        autohidesScrollers = true
        scrollerStyle = .overlay
        drawsBackground = false
        borderType = .noBorder
        contentView.postsBoundsChangedNotifications = true
        scrolling = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: contentView,
            queue: nil
        ) { [weak self] _ in
            // Posted on the main thread, where views are.
            MainActor.assumeIsolated { self?.grid.scrolled() }
        }
    }

    private var scrolling: (any NSObjectProtocol)?

    isolated deinit {
        if let scrolling { NotificationCenter.default.removeObserver(scrolling) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("made in code")
    }

    override func tile() {
        super.tile()
        grid.fit(width: contentSize.width)
        // It bounces only when it has something to scroll (the owner, 2026-11-17).
        verticalScrollElasticity = grid.frame.height > contentSize.height ? .allowed : .none
        horizontalScrollElasticity = .none
    }
}
