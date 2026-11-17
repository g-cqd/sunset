/// The options of Web (R1): downloads, websites, advanced.
extension SettingsOption {
    /// Downloads.
    static let downloads: [Self] =
        [
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

    /// What websites may do.
    static let websites: [Self] =
        [
            custom(
                "web.permissions",
                "Websites",
                "camera microphone location notifications popup permission screen",
                .websites
            )
            .setting(Configuration.Web.permissionNames.map { "web.permissions.\($0)" }),
            // The default for every site, and under it the sites that have a rule of their own (kept sealed, not in the file).
            custom(
                "web.agent",
                "Sites see Sunset as",
                "user agent chrome edge firefox safari appear impersonate browser disguise site rule",
                .siteAgents
            )
            .noted(
                "Changes what Sunset says it is (the User-Agent) at a page's next load: the engine is still WebKit, and a "
                    + "site can tell. A site can be given its own, from its panel in the address field."
            ),
            toggle(
                "web.agentScripts",
                "Tell a page's scripts the same",
                "user agent scripts navigator vendor client hints chrome detect",
                \.web.agentScripts
            )
            .noted(
                "A page shown Chrome, Edge or Firefox also reads that browser's vendor and client hints from its "
                    + "scripts. Turn it off if a site breaks: only the User-Agent is then changed. Applies to pages opened after."
            )
        ]

    /// For developers.
    static let webAdvanced: [Self] =
        [
            toggle(
                "web.developer",
                "Page inspector",
                "inspect developer devtools",
                \.web.developer,
                label: "Pages can be inspected (Inspect Element)"
            ),
            toggle(
                "web.fullFrameRate",
                "Pages render at the screen's full rate",
                "120 fps promotion frame animation smooth",
                \.web.fullFrameRate,
                label: "Pages render at the screen's full rate (120 fps on ProMotion)"
            )
        ]
}
