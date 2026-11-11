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

// Debug builds of the modules that do the work are optimised too: unoptimised Swift is 20 to 70 times slower on these loops (measured: a flood of 200 000 lines cost
// 52 G instructions in a debug build, against 2.4 G in release), which makes the app unusable to try. Assertions, preconditions and bounds checks stay on, and
// the app and the tests are still built for debugging. Set SUNSET_UNOPTIMIZED=1 to get the fully unoptimised build back (to step through the core in a debugger).
let optimized = Context.environment["SUNSET_UNOPTIMIZED"] == nil
let workSettings: [SwiftSetting] =
    strictSettings + (optimized ? [.unsafeFlags(["-O"], .when(configuration: .debug))] : [])
let workCSettings: [CSetting] = optimized ? [.unsafeFlags(["-O2"], .when(configuration: .debug))] : []

let package = Package(
    name: "Sunset",
    platforms: [.macOS(.v26)],
    products: [
        // The headless emulator core: VT parser, then screen, modes and replies (roadmap 0003).
        .library(name: "SunsetCore", targets: ["SunsetCore"]),
        // The host: a program on a pseudo-terminal feeding the core, with no window (roadmap 0004). The only target that imports the platform.
        .library(name: "SunsetHost", targets: ["SunsetHost"]),
        // What a window holds: panes arranged in splits, and the workspace of tabs made of them. Pure values, no UI (docs/research/arc-sidebar-spaces-2026-11-08.md).
        .library(name: "SunsetPane", targets: ["SunsetPane"]),
        // The window's shell (R8): the tabs of a window and what shows them, knowing no kind of content. It does not read the configuration file: it
        // has plain settings of its own (`ShellSettings`). Package access for now: nothing is promised outside this repository.
        .library(name: "SunsetShell", targets: ["SunsetShell"]),
        // The terminal as a kind of pane content: model, view, input (R8). Package access.
        .library(name: "SunsetTerminal", targets: ["SunsetTerminal"]),
        // The configuration file: schema, defaults, validation and the difference between two configurations (roadmap 0017). Platform-free.
        .library(name: "SunsetConfig", targets: ["SunsetConfig"]),
        // The private window-server calls the app uses (the blur radius behind a window), looked up by name at run time (roadmap 0017, ADR-0034).
        .library(name: "SunsetPrivate", targets: ["SunsetPrivate"]),
        // The CPU renderer: cells to pixels, the reference the GPU renderer is held to (ADR-0024). Platform-free; glyphs come from a `GlyphSource`.
        .library(name: "SunsetRender", targets: ["SunsetRender"]),
        // The macOS glyph source (CoreText), the platform seam of the renderer.
        .library(name: "SunsetRenderMac", targets: ["SunsetRenderMac"]),
        // The Metal renderer: replays the CPU renderer's draw list on the GPU (ADR-0024, ADR-0021); the CPU renderer is its oracle.
        .library(name: "SunsetRenderMetal", targets: ["SunsetRenderMetal"]),
        // Runs a program in a headless terminal and prints the screen.
        .executable(name: "sunset-run", targets: ["SunsetRun"]),
        // The first app shell: a window, one program, the CPU renderer.
        .executable(name: "sunset-app", targets: ["SunsetApp"]),
        // Runs a program in a headless terminal and writes what the CPU renderer draws of its screen as a PNG.
        .executable(name: "sunset-render", targets: ["SunsetRenderTool"])
    ],
    dependencies: [
        // Tests: the family's seeded generator, allocation counting and fuzz helpers (AemiTestKit). Pinned like TerminalKit's, which resolves the same revision.
        .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "e30aad82377cbea62171cc722a88041e97021db2"),
        // Our own tooling (ADR-0002): terminal display widths come from TerminalKitText. Pinned by revision, as the family does.
        .package(url: "https://github.com/g-cqd/TerminalKit.git", revision: "59668133b73f3d8ab77a347e03bbc778d929a2e6"),
        // The configuration file (roadmap 0017): JSON read by AemiJSON's engine. Pinned by revision, as the family does.
        .package(url: "https://github.com/g-cqd/AemiJSON.git", revision: "aec8895f1bc9bdaf2104b0d0ebe91e4a93b3c374")
    ],
    targets: [
        .target(
            name: "SunsetCore",
            dependencies: [
                .product(name: "TerminalKitText", package: "TerminalKit"),
                // Base64, percent-decoding and UTF-8 validation for the OSC sequences that carry data (ADR-0010).
                .product(name: "AemiKernel", package: "aemi"),
                "CSunsetKernels"
            ],
            path: "Sources/SunsetCore",
            swiftSettings: workSettings
        ),
        // Pixel kernels in C with NEON and a scalar fallback (docs/research/competitors-architecture-and-neon.md); each has a scalar reference it is tested against.
        .target(
            name: "CSunsetKernels",
            path: "Sources/CSunsetKernels",
            cSettings: workCSettings
        ),
        .target(
            name: "SunsetRender",
            dependencies: ["SunsetCore", "CSunsetKernels"],
            path: "Sources/SunsetRender",
            swiftSettings: workSettings
        ),
        .testTarget(
            name: "SunsetRenderTests",
            dependencies: [.product(name: "AemiTestKit", package: "aemi"), "SunsetRender", "SunsetCore"],
            path: "Tests/SunsetRenderTests",
            swiftSettings: workSettings
        ),
        .target(
            name: "SunsetRenderMac",
            dependencies: ["SunsetRender"],
            path: "Sources/SunsetRenderMac",
            swiftSettings: workSettings
        ),
        .target(
            name: "SunsetRenderMetal",
            dependencies: ["SunsetRender", "SunsetRenderMac"],
            path: "Sources/SunsetRenderMetal",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetRenderMetalTests",
            dependencies: ["SunsetRenderMetal", "SunsetRenderMac", "SunsetRender", "SunsetCore"],
            path: "Tests/SunsetRenderMetalTests",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetRenderMacTests",
            dependencies: [
                .product(name: "AemiTestKit", package: "aemi"), "SunsetRenderMac", "SunsetRender", "SunsetCore"
            ],
            path: "Tests/SunsetRenderMacTests",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "SunsetApp",
            dependencies: [
                "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane", "SunsetPrivate", "SunsetRender",
                "SunsetRenderMac", "SunsetRenderMetal", "SunsetShell", "SunsetShellBridge", "SunsetTerminal"
            ],
            path: "Sources/SunsetApp",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "SunsetRenderTool",
            dependencies: ["SunsetCore", "SunsetHost", "SunsetRender", "SunsetRenderMac"],
            path: "Sources/SunsetRenderTool",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetConfig",
            dependencies: [.product(name: "AemiJSONCore", package: "AemiJSON")],
            path: "Sources/SunsetConfig",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetConfigTests",
            dependencies: ["SunsetConfig"],
            path: "Tests/SunsetConfigTests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetPrivate",
            // The names of the private symbols are not written in the binary as plain strings: InternedStrings (Aemi) stores them obfuscated.
            dependencies: [.product(name: "InternedStrings", package: "aemi")],
            path: "Sources/SunsetPrivate",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetPrivateTests",
            dependencies: ["SunsetPrivate"],
            path: "Tests/SunsetPrivateTests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetPane",
            path: "Sources/SunsetPane",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetPaneTests",
            dependencies: ["SunsetPane"],
            path: "Tests/SunsetPaneTests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetShell",
            dependencies: ["SunsetPane"],
            path: "Sources/SunsetShell",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetShellTests",
            dependencies: ["SunsetShell", "SunsetPane"],
            path: "Tests/SunsetShellTests",
            swiftSettings: strictSettings
        ),
        // The terminal as a kind of pane content (R8: a target per kind): its model, its AppKit view, input, selection, the renderer's wiring.
        .target(
            name: "SunsetTerminal",
            dependencies: [
                "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane", "SunsetRender", "SunsetRenderMac",
                "SunsetRenderMetal", "SunsetShell"
            ],
            path: "Sources/SunsetTerminal",
            swiftSettings: strictSettings
        ),
        // What joins the configuration file to the shell's settings: a library so that the mapping is tested (the app target cannot be).
        .target(
            name: "SunsetShellBridge",
            dependencies: ["SunsetShell", "SunsetConfig"],
            path: "Sources/SunsetShellBridge",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetShellBridgeTests",
            dependencies: ["SunsetShellBridge", "SunsetShell", "SunsetConfig"],
            path: "Tests/SunsetShellBridgeTests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetHost",
            dependencies: ["SunsetCore", "SunsetConfig"],
            path: "Sources/SunsetHost",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "SunsetRun",
            dependencies: ["SunsetCore", "SunsetHost"],
            path: "Sources/SunsetRun",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetHostTests",
            dependencies: [.product(name: "AemiTestKit", package: "aemi"), "SunsetHost", "SunsetConfig"],
            path: "Tests/SunsetHostTests",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SunsetCoreTests",
            dependencies: [.product(name: "AemiTestKit", package: "aemi"), "SunsetCore"],
            path: "Tests/SunsetCoreTests",
            swiftSettings: strictSettings
        )
    ]
)
