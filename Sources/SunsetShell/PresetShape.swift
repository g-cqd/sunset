import AppKit
import SunsetPane
import SwiftUI

/// A layout drawn as its shape (its panes as rounded cells), for menus: no SF Symbol draws them all. A menu's palette does
/// not tint a template picture (seen black on a dark menu, 2026-11-17), so it is drawn white on a dark scheme, black on a
/// light one (the owner's ask).
enum PresetShape {
    @MainActor private static var drawn: [String: NSImage] = [:]

    /// The picture of `preset` for a menu of `dark` scheme, drawn once.
    /// - Parameters:
    ///   - preset: The layout.
    ///   - dark: The menu's scheme is dark.
    /// - Returns: A picture at a symbol's size in a menu.
    @MainActor static func image(_ preset: SplitPreset, dark: Bool) -> NSImage {
        let key = "\(preset.rawValue)-\(dark)"
        if let image = drawn[key] { return image }
        let size = NSSize(width: Design.Size.presetShapeWidth, height: Design.Size.presetShapeHeight)
        let image = NSImage(size: size, flipped: true) { bounds in
            let panes = (0 ..< preset.paneCount).map { _ in PaneID() }
            let frames = preset.layout(of: panes).frames(in: bounds.insetBy(dx: 1, dy: 1), gap: 1.5)
            (dark ? NSColor.white : NSColor.black).setFill()
            for pane in panes {
                guard let frame = frames[pane] else { continue }
                NSBezierPath(roundedRect: frame, xRadius: 1.5, yRadius: 1.5).fill()
            }
            return true
        }
        image.accessibilityDescription = preset.title
        drawn[key] = image
        return image
    }
}
