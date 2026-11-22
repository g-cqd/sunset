extension SettingsOption {
    /// Ads and trackers blocked by lists Sunset fetches itself.
    static let blocking: [Self] =
        [
            toggle(
                "web.blocking",
                "Block ads and trackers",
                "block ads trackers adblock easylist easyprivacy content blocker lists",
                \.web.blocking
            )
            .perProfile
            .noted(
                "Sunset fetches the lists below itself every few days (EasyList and EasyPrivacy, and any you add): the "
                    + "only requests it makes on its own. A site's panel pauses blocking there."
            ),
            custom(
                "web.blockingLists",
                "Lists fetched",
                "block lists easylist easyprivacy address updated rules",
                .blockingLists
            )
            .setting(["web.blockingLists"])
        ]
}
