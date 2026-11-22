package import SwiftUI

extension EnvironmentValues {
    /// The second line of a tab (its directory, a page's address) in the monospaced face: `tabs.bar.monospacedDirectory`, on by default.
    @Entry package var monospacedDetail = true
    /// The picture of a tab that is not running, when the app has one for what it would start from (a page: its site's
    /// icon, kept); nil: the kind's mark.
    @Entry package var savedPicture = SavedPictures()
}
