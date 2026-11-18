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
                "Remove download list items",
                "download list remove clear keep",
                \.web.keepDownloads,
                [
                    (.byHand, "Manually"), (.day, "After one day"), (.week, "After one week"),
                    (.month, "After one month"), (.untilQuit, "When Sunset quits"),
                    (.whenFinished, "Upon successful download")
                ]
            )
        ]

    /// The profiles (R4; ADR-0053): kept with the session, not in the file.
    static let profiles: [Self] =
        [
            custom("profiles.list", "Profiles", "profile identity cookies login account work personal", .profiles)
                .setting([])
                .noted(
                    "A profile is a web identity: its own cookies, logins, storage, Pinned grid and Favorites. History "
                        + "and what sites may do are shared by all profiles for now."
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
            toggle(
                "web.notificationsWithoutClick",
                "Ask about notifications without a click",
                "notification permission request gesture click chrome safari ask",
                \.web.notificationsWithoutClick
            )
            .noted(
                "On, a site may ask to notify as soon as it opens, as in Chrome; off, only after a click, as in Safari."
            )
            .further,
            toggle(
                "web.workerNotifications",
                "Notifications from a site's background script",
                "notification service worker push registration background",
                \.web.workerNotifications
            )
            .noted("The notifications a site sends through its service worker, while its page is open.")
            .further,
            // The default for every site, and under it the sites that have a rule of their own (kept sealed, not in the file).
            custom(
                "web.agent",
                "Browser shown to sites",
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
                "A page shown Chrome, Edge or Firefox also reads that browser's vendor and client hints. Turn it off if a "
                    + "site breaks; pages opened after follow."
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
                label: "Allow inspecting pages"
            )
            .noted("Adds Inspect Element to a page's menu."),
            toggle(
                "web.fullFrameRate",
                "Render pages at the screen's full rate",
                "120 fps promotion frame animation smooth",
                \.web.fullFrameRate,
                label: "Render pages at the screen's full rate"
            )
            .noted("120 frames a second on a ProMotion display.")
        ]
}
