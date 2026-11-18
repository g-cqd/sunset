extension ConfigurationKeys {
    /// The keys set in the file only, with no control in Settings (the owner's note n35, 2026-11-18: the paddings, spacings,
    /// margins and radii "figured out across the app"): the layout's measures but the floating sidebar's behaviour, the
    /// margin around the card, the card's radius.
    public static let fileOnly: Set<String> = {
        let behaviour: Set<String> = ["layout.hideDelay", "layout.revealStripWidth"]
        let measures = all.filter { $0.hasPrefix("layout.") && !behaviour.contains($0) }
        return Set(measures + ["sidebar.padding"])
    }()
}
