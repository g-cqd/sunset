public import MarkdownLookKit

/// What a page is made from, taken on the main actor and read off it: the parser's document as it stood, and the settings.
public struct DocumentPageSnapshot: Sendable {
    public var content: MarkdownSource.Content
    public var session: LabSession
    public var settings: ViewerSettings
}
