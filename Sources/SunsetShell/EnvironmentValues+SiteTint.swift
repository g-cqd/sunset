package import SwiftUI

extension EnvironmentValues {
    /// Which tabs take their site's colour (`tabs.siteColor`, the owner's note n56); none unless the window says.
    @Entry package var siteTint = RowFill.SiteTintMode.off
}
