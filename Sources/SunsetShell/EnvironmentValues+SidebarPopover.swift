package import SunsetShellModel
package import SwiftUI

extension EnvironmentValues {
    /// Set by `FloatingSidebar` so popovers inside the sidebar increment/decrement `sidebarPopoverCount` while open,
    /// preventing hovering into a popover from collapsing the floating sidebar.
    @Entry package var sidebarPopoverHost: TabsModel?
}
