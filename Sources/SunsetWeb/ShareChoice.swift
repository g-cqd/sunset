package import Foundation

/// What the person chose in Sunset's sheet.
package enum ShareChoice: Equatable, Sendable {
    /// macOS's own picker: a screen, a window or an app.
    case system
    case tab(UUID)
    case cancel
}
