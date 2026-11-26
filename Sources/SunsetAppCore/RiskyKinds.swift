internal import UniformTypeIdentifiers

/// The kinds macOS itself says run code or install it when opened: CoreTypes.bundle's `LSRiskCategoryUnsafeExecutable`,
/// and of `LSRiskCategoryMayContainUnsafeExecutable` the installers (not archives: unpacking one runs nothing), as of
/// macOS 26. Internet location files (`.fileloc`, `.inetloc`, `.webloc`) are links Sunset does not follow, so they are
/// shown too.
enum RiskyKinds {
    static let identifiers = words(
        """
        com.apple.mach-o-binary com.apple.webarchive com.apple.application com.apple.interfacebuilder.document
        com.apple.terminal.session com.apple.terminal.settings com.apple.terminal.shell-script com.sun.java-class
        com.sun.java-archive com.sun.java-web-start com.apple.quartz-composer-composition public.unix-executable
        com.apple.installer-distribution-package com.apple.installer-package com.apple.installer-package-archive
        com.apple.itunes.ipa com.apple.internet-location
        """
    )
    .compactMap { UTType(String($0)) }

    static let extensions = Set(
        words(
            """
            cin command gcx help ibplugin icp inputplugin menu nib service term terminal tool wflow x11app ipg ipa
            fileloc inetloc webloc
            """
        )
        .map(String.init)
    )

    static func conforms(_ kind: UTType) -> Bool {
        identifiers.contains { kind.conforms(to: $0) }
    }

    private static func words(_ text: String) -> [Substring] {
        text.split(whereSeparator: \.isWhitespace)
    }
}
