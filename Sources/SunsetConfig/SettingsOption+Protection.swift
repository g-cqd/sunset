/// Privacy and security > Protection on the web.
extension SettingsOption {
    static let webProtection: [Self] =
        [
            choice(
                "web.httpsUpgrade",
                "Secure connections",
                "https http upgrade secure insecure not secure",
                \.web.httpsUpgrade,
                [
                    (.fallback, "Try HTTPS first, then HTTP"), (.ask, "Try HTTPS first, ask before HTTP"),
                    (.only, "HTTPS only"), (.off, "As the address says")
                ]
            )
            .noted(
                "It decides for addresses typed without a scheme too. A page over HTTP shows Not Secure in its address."
            ),
            choice(
                "web.hardening",
                "Hardened pages",
                "jit hardening security memory tagging lockdown exploit",
                \.web.hardening,
                [(.off, "Off"), (.noJIT, "Without JIT, with more memory protection")]
            )
            .noted("Makes attacks on the web engine harder. Pages' scripts run slower; pages opened after follow."),
            choice(
                "web.globalPrivacyControl",
                "Global Privacy Control",
                "gpc do not sell track privacy signal",
                \.web.globalPrivacyControl,
                [(.privateWindows, "In private windows"), (.always, "Always"), (.off, "Never")]
            )
            .noted("Tells sites not to sell or share what they learn of you, where the law makes them listen.")
        ]
}
