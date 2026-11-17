import AppKit

/// One cell of the icon grid as accessibility sees it: a button with the icon's name, that picks it. The grid draws its
/// cells itself and has no view for each; these stand for the ones in sight.
final class IconGridCellElement: NSAccessibilityElement {
    private let press: () -> Void

    init(label: String, frame: NSRect, selected: Bool, parent: Any, press: @escaping () -> Void) {
        self.press = press
        super.init()
        setAccessibilityRole(.button)
        setAccessibilityLabel(label)
        setAccessibilityFrame(frame)
        setAccessibilitySelected(selected)
        setAccessibilityEnabled(true)
        setAccessibilityParent(parent)
    }

    override func accessibilityPerformPress() -> Bool {
        press()
        return true
    }
}
