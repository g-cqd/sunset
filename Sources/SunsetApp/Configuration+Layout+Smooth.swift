import SunsetConfig
import SwiftUI

extension Configuration.Layout {
    /// The one transition between states (hover, selection, pinning): eased, as long as `layout.animation` says.
    var smooth: Animation { .easeInOut(duration: animation) }
}
