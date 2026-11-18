package import SwiftUI

/// Whether the ends of lists and titles fade out (`appearance.ends`, the owner's note n30), or are cut. Apart from what is
/// under the bars (`barBlur`).
extension EnvironmentValues {
    @Entry package var fadesEnds = true
}
