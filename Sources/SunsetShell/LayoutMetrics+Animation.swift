package import SunsetMetrics
package import SwiftUI

extension LayoutMetrics {
    /// The one transition between states (hover, selection, pinning): eased, as long as `animation` says.
    package var smooth: Animation {
        .easeInOut(duration: animation)
    }

    /// A row becoming the shown one, or ceasing to be: slower and softer than a hover, so that it reads as a change of
    /// place (n114).
    package var selection: Animation {
        .smooth(duration: animation * 1.8)
    }
}
