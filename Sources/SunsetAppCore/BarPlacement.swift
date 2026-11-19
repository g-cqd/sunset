package import SunsetConfig

/// Where the built-in bar is (roadmap 0055): over the page (hidden until the pointer reaches the edge, or shown on the
/// page's fade), or in a toolbar of its own with the page below it. A bar that hides always floats.
package enum BarPlacement: Equatable, Sendable {
    case over(hides: Bool)
    case toolbar

    package init(_ bar: Configuration.Tabs.Bar) {
        self = !bar.autoHide && bar.backing == .toolbar ? .toolbar : .over(hides: bar.autoHide)
    }
}
