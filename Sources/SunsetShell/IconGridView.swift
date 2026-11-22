import AppKit

/// The icon picker's grid, as one view that draws itself ("the rendering and scrolling through the list should also be
/// instantaneous"). Only the cells of the part asked for are drawn, a symbol is rendered once into a picture and drawn
/// from it after (`IconPictures`), and the cell under the pointer is found by arithmetic (`IconGridLayout`). As SwiftUI
/// buttons, the seventy cells in sight cost 21 ms at each change of the list (measured, release).
final class IconGridView: NSView {
    private(set) var items: [IconChoice] = []
    var chosen: String? {
        didSet {
            if chosen != oldValue { needsDisplay = true }
        }
    }
    var accent = NSColor.controlAccentColor
    var onPick: (IconChoice) -> Void = { _ in }
    var onHover: (IconChoice?) -> Void = { _ in }
    private var hovered: Int?
    private var pressed: Int?
    private let pictures = IconPictures()
    private var tracking: NSTrackingArea?
    private var cells: [IconGridCellElement] = []

    override var isFlipped: Bool {
        true
    }
    override var acceptsFirstResponder: Bool {
        false
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    var layout: IconGridLayout {
        IconGridLayout(width: bounds.width, count: items.count)
    }

    /// Shows other icons, from the top.
    func show(_ new: [IconChoice]) {
        items = new
        hover(nil)
        fit(width: bounds.width)
        scroll(.zero)
        needsDisplay = true
    }

    /// As wide as the scroll view shows, as tall as its rows.
    func fit(width: CGFloat) {
        let size = NSSize(width: width, height: IconGridLayout(width: width, count: items.count).height)
        guard frame.size != size else { return }
        setFrameSize(size)
        needsDisplay = true
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let layout = layout
        for index in layout.indices(in: dirtyRect) {
            let item = items[index]
            let place = layout.rect(of: index)
            let cell = NSRect(
                x: place.minX + (place.width - IconGridLayout.cell.width) / 2,
                y: place.minY + (place.height - IconGridLayout.cell.height) / 2,
                width: IconGridLayout.cell.width,
                height: IconGridLayout.cell.height
            )
            if item.id == chosen || index == hovered {
                (item.id == chosen ? accent.withAlphaComponent(0.3) : NSColor.labelColor.withAlphaComponent(0.08))
                    .setFill()
                NSBezierPath(roundedRect: cell, xRadius: 6, yRadius: 6).fill()
            }
            _ = pictures.paint(item.id, centredOn: CGPoint(x: cell.midX, y: cell.midY), in: context)
        }
        prepareNearby()
    }

    /// Drawing never waits for an icon: those in sight that are not rendered yet are rendered meanwhile, then those of
    /// the three screens after and of the one before, and the view is drawn again when they are there. By what is in
    /// sight, not by what was asked to be drawn (AppKit draws ahead of the scrolling, and may ask for much more).
    private func prepareNearby() {
        let visible = layout.indices(in: visibleRect)
        let again: @MainActor () -> Void = { [weak self] in self?.needsDisplay = true }
        let inSight = visible.map { items[$0].id }
        guard pictures.missing(inSight).isEmpty else { return pictures.prepare(inSight, then: again) }
        let screen = max(visible.count, layout.columns)
        let ahead = visible.upperBound ..< min(visible.upperBound + 3 * screen, items.count)
        let behind = max(visible.lowerBound - screen, 0) ..< visible.lowerBound
        pictures.prepare((Array(ahead) + Array(behind)).map { items[$0].id }, then: again)
    }

    /// Whether every icon in sight is rendered (for measuring).
    var isComplete: Bool {
        pictures.missing(layout.indices(in: visibleRect).map { items[$0].id }).isEmpty
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        matchSurroundings()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        matchSurroundings()
    }

    /// The pictures are of the screen's scale and of the appearance's text colour.
    private func matchSurroundings() {
        var ink: [CGFloat] = [0, 0, 0, 1]
        effectiveAppearance.performAsCurrentDrawingAppearance {
            if let colour = NSColor.labelColor.usingColorSpace(.sRGB) {
                ink = [colour.redComponent, colour.greenComponent, colour.blueComponent, colour.alphaComponent]
            }
        }
        pictures.use(scale: window?.backingScaleFactor ?? 2, ink: ink)
        needsDisplay = true
    }

    // MARK: The pointer

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        tracking = area
    }

    private func index(of event: NSEvent) -> Int? {
        layout.index(at: convert(event.locationInWindow, from: nil))
    }

    private func hover(_ index: Int?) {
        guard index != hovered else { return }
        let layout = layout
        for changed in [hovered, index].compactMap(\.self) { setNeedsDisplay(layout.rect(of: changed)) }
        hovered = index
        onHover(index.map { items[$0] })
    }

    override func mouseMoved(with event: NSEvent) {
        hover(index(of: event))
    }
    override func mouseExited(with event: NSEvent) {
        hover(nil)
    }
    override func mouseDown(with event: NSEvent) {
        pressed = index(of: event)
    }

    override func mouseUp(with event: NSEvent) {
        defer { pressed = nil }
        guard let index = index(of: event), index == pressed else { return }
        onPick(items[index])
    }

    /// The view scrolled: what is under the pointer is another cell. (Not by overriding `scrollWheel`: a document view
    /// that does is scrolled the old way, without AppKit drawing ahead.)
    func scrolled() {
        guard let window,
            hovered != nil || visibleRect.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil))
        else { return }
        hover(layout.index(at: convert(window.mouseLocationOutsideOfEventStream, from: nil)))
    }

    // MARK: Accessibility

    override func isAccessibilityElement() -> Bool {
        true
    }
    override func accessibilityRole() -> NSAccessibility.Role? {
        .list
    }
    override func accessibilityLabel() -> String? {
        "Icons"
    }

    /// The cells in sight. Kept until asked again: who asks reads them after this returns.
    override func accessibilityChildren() -> [Any]? {
        guard let window else { return [] }
        let layout = layout
        cells = layout.indices(in: visibleRect)
            .map { index in
                let item = items[index]
                return IconGridCellElement(
                    label: item.label,
                    frame: window.convertToScreen(convert(layout.rect(of: index), to: nil)),
                    selected: item.id == chosen,
                    parent: self
                ) { [weak self] in self?.onPick(item) }
            }
        return cells
    }
}
