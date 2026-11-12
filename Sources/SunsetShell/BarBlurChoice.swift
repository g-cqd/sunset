package import SwiftUI

/// What is under the bars (`appearance.barBlur`): a fading blur, the bar's own surface, or nothing.
package enum BarBlurChoice: String, Sendable, Equatable {
    case variable, surface, none
}

extension EnvironmentValues {
    @Entry package var barBlur = BarBlurChoice.variable
}
