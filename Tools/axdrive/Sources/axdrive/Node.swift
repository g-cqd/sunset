import ApplicationServices
import Foundation

/// An element of an app's accessibility tree, with what it is known by.
struct Node {
    let element: AXUIElement
    let role: String
    let subrole: String
    let title: String
    let label: String
    let value: String
    let identifier: String
    let help: String
    let placeholder: String
    let enabled: Bool
    let frame: CGRect?
    /// Roles from the window down to it ("AXWindow/AXGroup/AXButton").
    let path: String
    let window: String

    init(_ element: AXUIElement, path: String, window: String) {
        self.element = element
        role = Self.string(element, kAXRoleAttribute)
        subrole = Self.string(element, kAXSubroleAttribute)
        title = Self.string(element, kAXTitleAttribute)
        label = Self.string(element, kAXDescriptionAttribute)
        let raw = Self.string(element, kAXValueAttribute)
        value = raw.count > 120 ? String(raw.prefix(120)) + "…" : raw
        identifier = Self.string(element, kAXIdentifierAttribute)
        help = Self.string(element, kAXHelpAttribute)
        placeholder = Self.string(element, kAXPlaceholderValueAttribute)
        enabled = Self.bool(element, kAXEnabledAttribute) ?? true
        frame = Self.frame(element)
        self.path = path
        self.window = window
    }

    /// The words a person would use for it, best first.
    var names: [String] { [title, label, identifier, placeholder, help, value].filter { !$0.isEmpty } }

    var summary: String {
        let name = names.first ?? "-"
        let where_ = frame.map { String(format: "@%.0f,%.0f %.0fx%.0f", $0.minX, $0.minY, $0.width, $0.height) } ?? ""
        return
            "\(role)\(subrole.isEmpty ? "" : "(\(subrole))") \"\(name)\"\(enabled ? "" : " [disabled]") \(where_) in \"\(window)\""
    }

    var actions: [String] {
        var names: CFArray?
        AXUIElementCopyActionNames(element, &names)
        return (names as? [String]) ?? []
    }

    static func string(_ element: AXUIElement, _ attribute: String) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success, let value else {
            return ""
        }
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    static func bool(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return (value as? NSNumber)?.boolValue
    }

    /// One element held by `attribute` (the menu bar).
    static func element(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success, let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    static func elements(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return [] }
        return (value as? [AXUIElement]) ?? []
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        var position: CFTypeRef?
        var size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size) == .success,
            let position, let size
        else { return nil }
        var point = CGPoint.zero
        var extent = CGSize.zero
        guard CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        AXValueGetValue(unsafeDowncast(position, to: AXValue.self), .cgPoint, &point)
        AXValueGetValue(unsafeDowncast(size, to: AXValue.self), .cgSize, &extent)
        return CGRect(origin: point, size: extent)
    }
}
