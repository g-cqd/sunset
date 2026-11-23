import SunsetShell

extension WebContent {
    /// The site's colour for its tab: its icon's, as the tab shows the icon (n118), else its declared theme colour, the
    /// first that stands out. (The window's accent goes the other way: the page's own colour first.)
    package var siteColor: [UInt8]? {
        [iconColor, themeColor].compactMap(\.self).first(where: Design.Accent.stands)
    }
}
