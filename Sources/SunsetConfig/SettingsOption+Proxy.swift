extension SettingsOption {
    /// The proxy every page goes through (roadmap 0022 W-f, first form).
    static let proxy: [Self] =
        [
            text("web.proxy", "Proxy", "proxy socks http connect network route tunnel", \.web.proxy, prompt: "None")
                .code()
                .noted(
                    "`http://host:port` or `socks5://host:port`. Every page, of every profile and private window, goes "
                        + "through it; Sunset's own requests do not yet."
                ),
            // Whether pages go through it (the owner's note n37).
            custom("web.proxyCheck", "Pages go through it", "proxy check test verify works", .proxyCheck)
                .setting([])
        ]
}
