package import SunsetConfig
package import SunsetShellModel

extension Configuration.Tabs.SiteColor {
    /// The setting as the rows read it.
    package var tintMode: RowFill.SiteTintMode {
        switch self {
            case .off: .off
            case .selected: .selected
            case .every: .every
        }
    }
}
