package import SunsetMetrics
package import SwiftUI

extension LayoutMetrics {
    /// The one transition between states (hover, selection, pinning): eased, as long as `animation` says.
    package var smooth: Animation { .easeInOut(duration: animation) }
}
