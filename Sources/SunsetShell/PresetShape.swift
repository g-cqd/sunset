import AppKit
import SunsetPane
import SwiftUI

/// A layout drawn as its shape (its panes as rounded cells), as a template picture for menus: no SF Symbol draws them all.
enum PresetShape {
    @MainActor private static var drawn: [SplitPreset: NSImage] = [:]

    /// The picture of `preset`, drawn once.
    /// - Parameter preset: The layout.
    /// - Returns: A template picture at a symbol's size in a menu.
    @MainActor static func image(_ preset: SplitPreset) -> NSImage {
        if let image = drawn[preset] { return image }
        let size = NSSize(width: Design.Size.presetShapeWidth, height: Design.Size.presetShapeHeight)
        let image = NSImage(size: size, flipped: true) { bounds in
            let panes = (0 ..< preset.paneCount).map { _ in PaneID() }
            let frames = preset.layout(of: panes).frames(in: bounds.insetBy(dx: 1, dy: 1), gap: 1.5)
            NSColor.black.setFill()
            for pane in panes {
                guard let frame = frames[pane] else { continue }
                NSBezierPath(roundedRect: frame, xRadius: 1.5, yRadius: 1.5).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = preset.title
        drawn[preset] = image
        return image
    }
}
