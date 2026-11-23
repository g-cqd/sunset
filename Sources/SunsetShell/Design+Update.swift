package import SwiftUI

extension Design {
    /// The update window (roadmap 0122, n135): the welcome's sky as a band at the top, the app's icon and the version on
    /// it; the notes in a column to read; the welcome's glass buttons.
    package enum Update {
        /// The window's size.
        package static let size = CGSize(width: 640, height: 600)
        /// The sky's band.
        package static let header = 168.0
        /// The app's icon on the band.
        package static let icon = 84.0
        /// Around the content: the welcome's margin, less (a smaller window).
        package static let margin = 32.0
        /// The notes' column: about 75 characters of body text.
        package static let column = 540.0
        /// A nested item's indent per level.
        package static let indent = 18.0
        /// The bullet's column.
        package static let bullet = 12.0
        /// The dimming over the band, under the text (as the welcome's).
        package static let dimming = Welcome.dimming
        /// How long the window's states take to change.
        package static let change = Animation.smooth(duration: 0.3)
    }
}
