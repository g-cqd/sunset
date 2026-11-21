extension ExtensionHosts {
    /// The window `page` is a tab of: the one showing it, else the first holding it (a pinned or favorite page can be in
    /// several windows of its profile).
    func window(of page: WebContent) -> ExtensionWindow? {
        let all = windows()
        return all.first { $0.shown() === page } ?? all.first { $0.holds(page) }
    }
}
