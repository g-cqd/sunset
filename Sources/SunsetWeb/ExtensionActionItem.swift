package import AppKit

/// An extension's action as its button shows it, for one page (roadmap 0109 D).
package struct ExtensionActionItem: Identifiable {
    /// The extension's context's identifier.
    package let id: String
    package let label: String
    package let icon: NSImage?
    package let badge: String
    package let enabled: Bool
}
