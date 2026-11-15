/// The options of the Web pane (R1): what is kept, downloads, private pages, websites.
extension SettingsOption {
    static let webKept: [Self] = [
        choice(
            "web.historyKeep",
            "Keep history for",
            "history remove days",
            \.web.historyKeep,
            [
                (.day, "One day"), (.week, "One week"), (.twoWeeks, "Two weeks"), (.month, "One month"),
                (.year, "One year"), (.forever, "Always")
            ],
            label: "Keep the history of pages for"
        ),
        toggle(
            "web.clearHistoryOnQuit",
            "Clear history when Sunset quits",
            "history quit privacy",
            \.web.clearHistoryOnQuit,
            label: "Clear the history when Sunset quits"
        ),
        toggle(
            "web.clearWebsiteDataOnQuit",
            "Clear website data when Sunset quits",
            "cookies cache quit privacy",
            \.web.clearWebsiteDataOnQuit,
            label: "Clear website data when Sunset quits (signs you out of sites)"
        )
    ]

    static let webDownloads: [Self] = [
        text(
            "web.downloadFolder",
            "Download folder",
            "download folder save where path",
            \.web.downloadFolder,
            prompt: "~/Downloads"
        ),
        toggle(
            "web.askWhereToSave",
            "Ask where to save each download",
            "download save ask panel where",
            \.web.askWhereToSave
        ),
        toggle(
            "web.openSafeDownloads",
            "Open safe files once downloaded",
            "download open picture pdf text sound film",
            \.web.openSafeDownloads
        )
        .noted("Pictures, PDF, text, sound and film. Never an app, an installer or a script."),
        toggle(
            "web.notifyDownloads",
            "Notify when a download has finished",
            "download notification banner finished",
            \.web.notifyDownloads
        ),
        toggle(
            "web.approveRiskyDownloads",
            "Approve apps, installers and scripts",
            "download risky app installer script approve security",
            \.web.approveRiskyDownloads,
            label: "Apps, installers and scripts are downloaded only after an approval"
        ),
        choice(
            "web.keepDownloads",
            "Keep the list of downloads",
            "download list remove clear keep",
            \.web.keepDownloads,
            [
                (.byHand, "Until removed by hand"), (.day, "One day"), (.week, "One week"), (.month, "One month"),
                (.untilQuit, "Until Sunset quits"), (.whenFinished, "Only while they download")
            ],
            label: "A finished download stays in the list"
        )
    ]

    static let webPrivate: [Self] = [
        toggle(
            "web.privateSuggestions",
            "Suggestions in private pages",
            "private incognito suggest",
            \.web.privateSuggestions,
            label: "Ask the engine for suggestions in private pages"
        ),
        toggle(
            "web.privateWindowShares",
            "Private windows share their data",
            "private incognito store cookies",
            \.web.privateWindowShares,
            label: "The pages of a new private window share their data (a private tab of a normal window never does)"
        ),
        custom(
            "web.permissions",
            "Websites",
            "camera microphone location notifications popup permission screen",
            .websites
        )
        .setting(Configuration.Web.permissionNames.map { "web.permissions.\($0)" }),
        custom("web.engines", "Added search engines", "engine keyword custom", .engines)
    ]
}
