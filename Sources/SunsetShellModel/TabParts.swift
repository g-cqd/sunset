/// What a tab's label shows: its picture, its title, its second line (a directory) and the progress its program reports
/// (the four were passed one by one, together, to every row and label).
package struct TabParts: Sendable, Equatable {
    package var icon: Bool
    package var title: Bool
    package var directory: Bool
    package var progress: Bool

    package init(icon: Bool = false, title: Bool = true, directory: Bool = false, progress: Bool = true) {
        self.icon = icon
        self.title = title
        self.directory = directory
        self.progress = progress
    }
}

extension ShellSettings.Bar {
    /// What the tabs' labels show, as the tab bar's settings say.
    package var parts: TabParts {
        TabParts(icon: showIcon, title: showTitle, directory: showDirectory, progress: showProgress)
    }
}
