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
        .library(name: "SunsetCore", targets: ["SunsetCore"]),
        // The host: a program on a pseudo-terminal feeding the core, with no window (roadmap 0004). The only target that imports the platform.
        .library(name: "SunsetHost", targets: ["SunsetHost"]),
        // The CPU renderer: cells to pixels, the reference the GPU renderer is held to (ADR-0024). Platform-free; glyphs come from a `GlyphSource`.
        .library(name: "SunsetRender", targets: ["SunsetRender"]),
        // The macOS glyph source (CoreText), the platform seam of the renderer.
        .library(name: "SunsetRenderMac", targets: ["SunsetRenderMac"]),
        // Runs a program in a headless terminal and prints the screen.
        .executable(name: "sunset-run", targets: ["SunsetRun"]),
        // Runs a program in a headless terminal and writes what the CPU renderer draws of its screen as a PNG.
        .executable(name: "sunset-render", targets: ["SunsetRenderTool"])
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
        .target(
            name: "SunsetRender",
            dependencies: ["SunsetCore"],
            path: "Sources/SunsetRender",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetRenderTests",
            dependencies: ["SunsetRender", "SunsetCore"],
            path: "Tests/SunsetRenderTests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetRenderMac",
            dependencies: ["SunsetRender"],
            path: "Sources/SunsetRenderMac",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetRenderMacTests",
            dependencies: ["SunsetRenderMac", "SunsetRender"],
            path: "Tests/SunsetRenderMacTests",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "SunsetRenderTool",
            dependencies: ["SunsetCore", "SunsetHost", "SunsetRender", "SunsetRenderMac"],
            path: "Sources/SunsetRenderTool",
            swiftSettings: [.swiftLanguageMode(.v5)]  // a script-style main with globals
        ),
        .target(
            name: "SunsetHost",
            dependencies: ["SunsetCore"],
            path: "Sources/SunsetHost",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "SunsetRun",
            dependencies: ["SunsetCore", "SunsetHost"],
            path: "Sources/SunsetRun",
            swiftSettings: [.swiftLanguageMode(.v5)]  // a script-style main with globals
        ),
        .testTarget(
            name: "SunsetHostTests",
            dependencies: ["SunsetHost"],
            path: "Tests/SunsetHostTests",
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
