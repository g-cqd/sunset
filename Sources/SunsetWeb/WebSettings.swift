/// What a page is made with, from the app's configuration (`web.*`).
package struct WebSettings: Sendable, Equatable {
    /// The end of the user agent (`SafariName`).
    package var applicationName: String
    /// The inspector can be opened.
    package var developer: Bool
    /// The tab shows the first letter of the title (true) or a globe.
    package var initialIcon: Bool

    package init(
        applicationName: String = SafariName.applicationName(),
        developer: Bool = true,
        initialIcon: Bool = true
    ) {
        self.applicationName = applicationName
        self.developer = developer
        self.initialIcon = initialIcon
    }
}
