import SunsetShell

extension WebContent {
    /// The site's colour for its tab: its declared theme colour, else its icon's, when it stands out.
    package var siteColor: [UInt8]? {
        Design.Accent.siteColor(theme: themeColor, icon: iconColor)
    }
}
