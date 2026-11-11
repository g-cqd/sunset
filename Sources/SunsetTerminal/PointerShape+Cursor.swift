package import AppKit
package import SunsetCore

extension PointerShape {
    /// The system's pointer nearest to the shape (AppKit has fewer than CSS names: the diagonal resizes and the scroll-all become the nearest it has).
    package var cursor: NSCursor {
        switch self {
            case .arrow, .cell, .allScroll, .progress, .wait, .help: .arrow
            case .text: .iBeam
            case .verticalText: .iBeamCursorForVerticalLayout
            case .pointer: .pointingHand
            case .crosshair: .crosshair
            case .move, .grab: .openHand
            case .grabbing: .closedHand
            case .notAllowed, .noDrop: .operationNotAllowed
            case .copy: .dragCopy
            case .alias: .dragLink
            case .contextMenu: .contextualMenu
            case .zoomIn: .zoomIn
            case .zoomOut: .zoomOut
            case .eastWestResize, .columnResize, .eastResize, .westResize: .resizeLeftRight
            case .northSouthResize, .rowResize, .northResize, .southResize: .resizeUpDown
            case .northEastSouthWestResize, .northWestSouthEastResize: .crosshair
        }
    }
}
