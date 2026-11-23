/// The options of Web: downloads, websites, advanced.
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
            )
            .perProfile
            .folder()
            .grouped("Saving"),
            toggle(
                "web.askWhereToSave",
                "Ask where to save each download",
                "download save ask panel where",
                \.web.askWhereToSave
            )
            .perProfile
            .grouped("Saving"),
            toggle(
                "web.approveRiskyDownloads",
                "Approve apps, installers and scripts",
                "download risky app installer script approve security",
                \.web.approveRiskyDownloads,
                label: "Apps, installers and scripts are downloaded only after an approval"
            )
            .grouped("Saving"),
            toggle(
                "web.openSafeDownloads",
                "Open safe files once downloaded",
                "download open picture pdf text sound film",
                \.web.openSafeDownloads
            )
            .noted("Pictures, PDF, text, audio and video. Never an app, an installer or a script.")
            .grouped("Once downloaded"),
            toggle(
                "web.notifyDownloads",
                "Notify when a download has finished",
                "download notification banner finished",
                \.web.notifyDownloads
            )
            .grouped("Once downloaded"),
            choice(
                "web.keepDownloads",
                "Remove downloads from the list",
                "download list remove clear keep",
                \.web.keepDownloads,
                [
                    (.byHand, "Manually"), (.day, "After one day"), (.week, "After one week"),
                    (.month, "After one month"), (.untilQuit, "When Sunset quits"),
                    (.whenFinished, "When the download finishes")
                ]
            )
            .grouped("Once downloaded")
        ]

    /// The profiles: kept with the session, not in the file.
    static let profiles: [Self] =
        [
            custom("profiles.list", "Your profiles", "profile identity cookies login account work personal", .profiles)
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
                "What sites may do",
                "camera microphone location notifications popup permission screen",
                .websites
            )
            .setting(Configuration.Web.permissionNames.map { "web.permissions.\($0)" })
            .noted(
                "Each choice is what a site gets until you answer it; the sites answered are listed under it, each "
                    + "changeable."
            ),
            toggle(
                "web.notificationsWithoutClick",
                "Let sites ask to notify without a click",
                "notification permission request gesture click chrome safari ask",
                \.web.notificationsWithoutClick
            )
            .noted(
                "On, a site may ask to notify as soon as it opens, as in Chrome; off, only after a click, as in Safari."
            )
            .further,
            toggle(
                "web.workerNotifications",
                "Allow notifications from background scripts",
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
            .perProfile
            .noted(
                "Changes what Sunset says it is (the User-Agent) at a page's next load: the engine is still WebKit, and a "
                    + "site can tell. A site can be given its own, from its panel in the address field."
            ),
            toggle(
                "web.agentScripts",
                "Show the same browser to page scripts",
                "user agent scripts navigator vendor client hints chrome detect",
                \.web.agentScripts
            )
            .perProfile
            .grouped("Browser shown to sites")
            .noted(
                "A page shown Chrome, Edge or Firefox also reads that browser's vendor and client hints. Turn it off if a "
                    + "site breaks; pages opened after follow."
            ),
            media(
                ("web.nowPlaying", "Now Playing", "Show what plays at the foot of the sidebar"),
                "now playing media music video audio play pause next previous mute cards sidebar",
                \.web.nowPlaying,
                "A card for each page that plays: play and pause, previous and next, mute, and the way to its tab."
            ),
            media(
                ("web.pictureInPicture", "Picture in picture", "Allow picture in picture for videos"),
                "picture in picture pip video float window",
                \.web.pictureInPicture,
                "A video can float in its own small window above the others, as in Safari."
            ),
            media(
                ("web.autoPictureInPicture", "Float when leaving", "Float a playing video when you leave its tab"),
                "picture in picture pip automatic auto float video leave switch tab return",
                \.web.autoPictureInPicture,
                "A video that plays floats in picture in picture when you show another tab, and goes back in its page when you "
                    + "come back to it."
            )
        ]

    /// A switch of the Media group: its key, title and label; its search words, its value, its sentence.
    private static func media(
        _ names: (key: String, title: String, label: String),
        _ words: String,
        _ path: Path<Bool>,
        _ note: String
    ) -> Self {
        toggle(names.key, names.title, words, path, label: names.label).noted(note).grouped("Media")
    }

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
