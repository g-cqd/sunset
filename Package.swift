// swift-tools-version: 6.4
import PackageDescription

// Sunset: a Swift terminal emulator (docs/WHITE-PAPER.md). The core is platform-free (ADR-0003): no Darwin-only API, no UI. Benchmarks and probes
// live in their own package (Benchmarks/). Strictness is the family's: Swift 6 mode, strict memory safety, warnings as errors.
let strictSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("StrictMemorySafety"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error)
]

let package = Package(
    name: "Sunset",
    platforms: [.macOS(.v26)],
    products: [
        // The headless emulator core: VT parser, then screen, modes and replies (roadmap 0003).
        .library(name: "SunsetCore", targets: ["SunsetCore"])
    ],
    dependencies: [
        // Our own tooling (ADR-0002): terminal display widths come from TerminalKitText. Pinned by revision, as the family does.
        .package(url: "https://github.com/g-cqd/TerminalKit.git", revision: "59668133b73f3d8ab77a347e03bbc778d929a2e6")
    ],
    targets: [
        .target(
            name: "SunsetCore",
            dependencies: [.product(name: "TerminalKitText", package: "TerminalKit")],
            path: "Sources/SunsetCore",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetCoreTests",
            dependencies: ["SunsetCore"],
            path: "Tests/SunsetCoreTests",
            swiftSettings: strictSettings
        )
    ]
)
