package import SunsetHelp
package import SwiftUI

extension View {
    /// The topic's one-sentence summary as this control's tooltip: the same words as its explanation.
    /// - Parameter topic: What the control is.
    /// - Returns: The view with its tooltip.
    package func helpTopic(_ topic: HelpTopic) -> some View {
        help(HelpCatalog.entry(topic).summary)
    }
}
