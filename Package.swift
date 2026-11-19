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

/// A module of Sunset's, at `Sources/<name>`.
func module(_ name: String, _ dependencies: [Target.Dependency], settings: [SwiftSetting] = strictSettings) -> Target {
    .target(name: name, dependencies: dependencies, path: "Sources/\(name)", swiftSettings: settings)
}

/// A module's tests, at `Tests/<name>`.
func tests(_ name: String, _ dependencies: [Target.Dependency], settings: [SwiftSetting] = strictSettings) -> Target {
    .testTarget(name: name, dependencies: dependencies, path: "Tests/\(name)", swiftSettings: settings)
}

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
        // A web page as a kind of pane content (R1). Package access.
        .library(name: "SunsetWeb", targets: ["SunsetWeb"]),
        // The configuration file: schema, defaults, validation and the difference between two configurations (roadmap 0017). Platform-free.
        .library(name: "SunsetConfig", targets: ["SunsetConfig"]),
        // Where everything Sunset keeps is, written whole or not at all, and what is done with a file that does not read (R12, roadmap 0030).
        .library(name: "SunsetStorage", targets: ["SunsetStorage"]),
        .library(name: "SunsetDocuments", targets: ["SunsetDocuments"]),
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
        .executable(name: "sunset-app", targets: ["SunsetAppMain"]),
        // What Sunset.app links (project.yml, built by XcodeGen and xcodebuild).
        .library(name: "SunsetAppLibrary", targets: ["SunsetApp"]),
        // Runs a program in a headless terminal and writes what the CPU renderer draws of its screen as a PNG.
        .executable(name: "sunset-render", targets: ["SunsetRenderTool"])
    ],
    dependencies: [
        // Tests: the family's seeded generator, allocation counting and fuzz helpers (AemiTestKit). Pinned like TerminalKit's, which resolves the same revision.
        .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "8db567405295d7d8aa4852a66af1cd46bf46a617"),
        // Our own tooling (ADR-0002): terminal display widths come from TerminalKitText. Pinned by revision, as the family does.
        .package(url: "https://github.com/g-cqd/TerminalKit.git", revision: "91b628b5ce1581452fdbfc3ca4bb7f942ab57abd"),
        // Markdown, Mermaid and text documents (roadmap 0023): the native view, the source editor, the one text behind them.
        .package(
            url: "https://github.com/g-cqd/AemiMarkdown.git",
            revision: "5ea4aeb23e9fa4f48066cf8f6e494c1c5573e28a"
        ),
        // The configuration file (roadmap 0017): JSON read by AemiJSON's engine. Pinned by revision, as the family does.
        .package(url: "https://github.com/g-cqd/AemiJSON.git", revision: "5114554d1cbb16625556fec05669a00eaf4ada89"),
        // Blur under the bars and panels (Sunset research/blur, AemiSDR roadmap 0020). Pinned by revision, as the family does.
        .package(
            url: "https://github.com/Aemi-Studio/AemiSDR.git",
            revision: "2e0991d7215557ba400a5ed0457ca2a600b03e36"
        )
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
        module("SunsetRender", ["SunsetCore", "CSunsetKernels"], settings: workSettings),
        tests("SunsetRuntimeTests", ["SunsetRuntime", .product(name: "AemiTestKit", package: "aemi")]),
        tests(
            "SunsetRenderTests",
            ["SunsetTestSupport", .product(name: "AemiTestKit", package: "aemi"), "SunsetRender", "SunsetCore"],
            settings: workSettings
        ),
        module("SunsetRenderMac", ["SunsetRuntime", "SunsetRender"], settings: workSettings),
        module("SunsetRenderMetal", ["SunsetRuntime", "SunsetRender", "SunsetRenderMac"]),
        tests(
            "SunsetRenderMetalTests",
            ["SunsetTestSupport", "SunsetRenderMetal", "SunsetRenderMac", "SunsetRender", "SunsetCore"]
        ),
        tests(
            "SunsetRenderMacTests",
            [
                "SunsetTestSupport", .product(name: "AemiTestKit", package: "aemi"), "SunsetRenderMac", "SunsetRender",
                "SunsetCore"
            ]
        ),
        .executableTarget(
            name: "SunsetAppMain",
            dependencies: ["SunsetApp"],
            path: "Sources/SunsetAppMain",
            swiftSettings: strictSettings
        ),
        module(
            "SunsetApp",
            [
                "SunsetRuntime", "SunsetHelp", "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane",
                "SunsetPrivate", "SunsetRender", "SunsetStorage", "SunsetDocuments", "SunsetRenderMac",
                "SunsetRenderMetal", "SunsetShell", "SunsetShellBridge", "SunsetTerminal", "SunsetWeb",
                "SunsetMarkdown", "SunsetMetrics", .product(name: "AemiSDR", package: "AemiSDR"),
                .product(name: "MarkdownLookKit", package: "AemiMarkdown")
            ]
        ),
        .executableTarget(
            name: "SunsetRenderTool",
            dependencies: ["SunsetCore", "SunsetHost", "SunsetRender", "SunsetRenderMac"],
            path: "Sources/SunsetRenderTool",
            swiftSettings: strictSettings
        ),
        // Tasks and time through seams (ADR-0087): the `TaskProvider`, the `Clock` and the "now" every module is given, live
        // by default, a spy and a test clock in tests (AemiRuntime, AemiTestKit).
        // What every test target shares: the time and the tasks of what a test runs (ADR-0087).
        .target(
            name: "SunsetTestSupport",
            dependencies: ["SunsetRuntime", .product(name: "AemiTestKit", package: "aemi")],
            path: "Tests/SunsetTestSupport",
            swiftSettings: strictSettings
        ),
        module("SunsetRuntime", [.product(name: "AemiRuntime", package: "aemi")]),
        // The interface's measures (`layout.*`): one list, read by the configuration and drawn by the shell (design 0003).
        module("SunsetMetrics", []),
        // Documents (R6, R12): the store of those that live in Sunset (one sealed file each, an index rebuilt from them), and
        // the one document behind every pane on a file or a stored document (its text, saving, watching the file).
        .target(
            name: "SunsetDocuments",
            dependencies: [
                "SunsetRuntime",
                "SunsetRuntime",
                "SunsetStorage", "SunsetHost", .product(name: "MarkdownLookKit", package: "AemiMarkdown"),
                // The parser itself: a text cut at its top-level blocks, for merging a change on disk (step M-e).
                .product(name: "AemiMarkdown", package: "AemiMarkdown"),
                .product(name: "AemiIO", package: "aemi")
            ],
            path: "Sources/SunsetDocuments",
            swiftSettings: strictSettings
        ),
        tests(
            "SunsetDocumentsTests",
            [
                "SunsetDocuments", "SunsetStorage", "SunsetTestSupport",
                .product(name: "MarkdownLookKit", package: "AemiMarkdown")
            ]
        ),
        module("SunsetStorage", ["SunsetRuntime", .product(name: "AemiIO", package: "aemi")]),
        tests("SunsetStorageTests", ["SunsetTestSupport", "SunsetStorage"]),
        module("SunsetConfig", [.product(name: "AemiJSONCore", package: "AemiJSON"), "SunsetMetrics"]),
        tests("SunsetConfigTests", ["SunsetTestSupport", "SunsetConfig", "SunsetMetrics"]),
        .target(
            name: "SunsetPrivate",
            // The names of the private symbols are not written in the binary as plain strings: InternedStrings (Aemi) stores them obfuscated.
            dependencies: ["SunsetRuntime", .product(name: "InternedStrings", package: "aemi")],
            path: "Sources/SunsetPrivate",
            swiftSettings: strictSettings
        ),
        tests("SunsetPrivateTests", ["SunsetTestSupport", "SunsetPrivate"]),
        module("SunsetPane", []),
        tests("SunsetPaneTests", ["SunsetTestSupport", "SunsetPane"]),
        // Help (roadmap 0041): its topics and their texts, one source for a control's tooltip and its explanation. No UI.
        module("SunsetHelp", []),
        module(
            "SunsetShell",
            [
                "SunsetRuntime", "SunsetPane", "SunsetMetrics", "SunsetHelp",
                .product(name: "AemiSDR", package: "AemiSDR")
            ]
        ),
        tests(
            "SunsetShellTests",
            ["SunsetTestSupport", "SunsetShell", "SunsetPane", "SunsetMetrics", "SunsetHelp", "SunsetConfig"]
        ),
        // The terminal as a kind of pane content (R8: a target per kind): its model, its AppKit view, input, selection, the renderer's wiring.
        module(
            "SunsetTerminal",
            [
                "SunsetRuntime", "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane", "SunsetRender",
                "SunsetRenderMac", "SunsetRenderMetal", "SunsetShell", "SunsetMetrics"
            ]
        ),
        // A document as a kind of pane content (R6, roadmap 0023 step M-c): Markdown and Mermaid drawn natively or as source,
        // any other text as source, on the one document `SunsetDocuments` holds for the app.
        module(
            "SunsetMarkdown",
            [
                "SunsetRuntime", "SunsetPane", "SunsetShell", "SunsetDocuments", "SunsetMetrics",
                .product(name: "MarkdownLookKit", package: "AemiMarkdown")
            ]
        ),
        tests(
            "SunsetMarkdownTests",
            [
                "SunsetTestSupport",
                "SunsetMarkdown", "SunsetPane", "SunsetShell", "SunsetDocuments",
                .product(name: "MarkdownLookKit", package: "AemiMarkdown")
            ]
        ),
        // A web page as a kind of pane content (R1, roadmap 0019), on the system's WebKit.
        module(
            "SunsetWeb",
            [
                "SunsetRuntime", "SunsetPane", "SunsetShell", "SunsetPrivate", "SunsetMetrics", "SunsetStorage",
                .product(name: "AemiSDR", package: "AemiSDR")
            ]
        ),
        tests(
            "SunsetWebTests",
            ["SunsetTestSupport", "SunsetWeb", "SunsetPane", "SunsetShell", "SunsetMetrics", "SunsetStorage"]
        ),
        // What joins the configuration file to the shell's settings: a library so that the mapping is tested (the app target cannot be).
        module("SunsetShellBridge", ["SunsetShell", "SunsetConfig", "SunsetMetrics"]),
        tests(
            "SunsetShellBridgeTests",
            ["SunsetTestSupport", "SunsetShellBridge", "SunsetShell", "SunsetConfig", "SunsetMetrics"]
        ),
        module("SunsetHost", ["SunsetRuntime", "SunsetCore", "SunsetConfig", "SunsetMetrics"]),
        .executableTarget(
            name: "SunsetRun",
            dependencies: ["SunsetCore", "SunsetHost"],
            path: "Sources/SunsetRun",
            swiftSettings: strictSettings
        ),
        tests(
            "SunsetHostTests",
            [
                "SunsetTestSupport", .product(name: "AemiTestKit", package: "aemi"), "SunsetHost", "SunsetConfig",
                "SunsetMetrics"
            ]
        ),
        tests("SunsetCoreTests", ["SunsetTestSupport", .product(name: "AemiTestKit", package: "aemi"), "SunsetCore"])
    ]
)
