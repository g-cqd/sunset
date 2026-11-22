package import SwiftUI

extension EnvironmentValues {
    /// The built-in tab bar holds the address: its tabs, the address field, back and forward and + are all capsules of one
    /// height (`Design.TabCapsules`), the field's fill and hairline (all alike).
    @Entry package var tabCapsules = false
    /// A pinned tab of that row: a circle with its icon only.
    @Entry package var tabIconOnly = false
}
