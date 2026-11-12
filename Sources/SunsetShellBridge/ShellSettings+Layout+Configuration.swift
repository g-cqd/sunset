package import SunsetConfig
import SunsetShell

extension ShellSettings.Layout {
    /// The shell's measures as `layout.*` says them: the same list (`LayoutMetrics`), so nothing is copied field by field.
    package init(_ layout: Configuration.Layout) { self = layout }
}
