import SunsetPane

/// Where a content is, for what it asks (S-e): the Space whose tabs hold it.
extension SpacesModel {
    /// The Space one of whose tabs holds `content`; nil for a kept entry's, or one of no Space of the app's.
    /// - Parameter content: a pane's content.
    /// - Returns: its Space, or nil.
    package func space(holding content: any PaneContent) -> SpaceModel? {
        spaces.first { space in space.contents.values.contains { $0 === content } }
    }
}
