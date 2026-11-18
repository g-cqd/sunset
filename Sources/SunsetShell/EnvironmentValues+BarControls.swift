package import SwiftUI

/// The controls are in a glass bar (`barGroup`): its icon buttons rest in the primary colour, not the sidebar's secondary,
/// which read as inactive there (the owner's note n43).
extension EnvironmentValues {
    @Entry package var inBarGroup = false
}
