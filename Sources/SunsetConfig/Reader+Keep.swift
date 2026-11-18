internal import OrderedCollections

extension Reader {
    /// `web.keep` (ADR-0081): what WebKit keeps between runs.
    mutating func readKeep(_ object: Object) {
        for (key, value) in object {
            let path = "web.keep.\(key)"
            switch key {
                case "cache":
                    if let choice = choice(path, value, as: Configuration.Web.Keep.Choice.self) {
                        configuration.web.keep.cache = choice
                    }
                case "traces":
                    if let choice = choice(path, value, as: Configuration.Web.Keep.Choice.self) {
                        configuration.web.keep.traces = choice
                    }
                case "siteData":
                    if let choice = choice(path, value, as: Configuration.Web.Keep.SiteData.self) {
                        configuration.web.keep.siteData = choice
                    }
                default: unknown(path)
            }
        }
    }
}
