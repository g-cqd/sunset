/// A shape for the mouse pointer, by its CSS name (what OSC 22 carries): the host shows the nearest the system has.
public enum PointerShape: String, Sendable, Equatable, CaseIterable {
    case arrow = "default"
    case text
    case pointer
    case crosshair
    case wait
    case progress
    case help
    case move
    case notAllowed = "not-allowed"
    case noDrop = "no-drop"
    case grab
    case grabbing
    case copy
    case alias
    case cell
    case verticalText = "vertical-text"
    case contextMenu = "context-menu"
    case zoomIn = "zoom-in"
    case zoomOut = "zoom-out"
    case allScroll = "all-scroll"
    case eastWestResize = "ew-resize"
    case northSouthResize = "ns-resize"
    case columnResize = "col-resize"
    case rowResize = "row-resize"
    case eastResize = "e-resize"
    case westResize = "w-resize"
    case northResize = "n-resize"
    case southResize = "s-resize"
    case northEastSouthWestResize = "nesw-resize"
    case northWestSouthEastResize = "nwse-resize"

    /// The shape `name` (ASCII bytes) names, if it is one.
    init?(name: some Sequence<UInt8>) {
        guard let shape = Self.allCases.first(where: { $0.rawValue.utf8.elementsEqual(name) }) else { return nil }
        self = shape
    }
}
