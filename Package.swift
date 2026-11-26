// swift-tools-version: 6.4
import PackageDescription

let strictSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("StrictMemorySafety"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error)
]

let optimized = Context.environment["SUNSET_UNOPTIMIZED"] == nil
let workSettings: [SwiftSetting] =
    strictSettings + (optimized ? [.unsafeFlags(["-O"], .when(configuration: .debug))] : [])
let workCSettings: [CSetting] = optimized ? [.unsafeFlags(["-O2"], .when(configuration: .debug))] : []

func module(_ name: String, _ dependencies: [Target.Dependency], settings: [SwiftSetting] = strictSettings) -> Target {
    .target(name: name, dependencies: dependencies, path: "Sources/\(name)", swiftSettings: settings)
}

func tests(_ name: String, _ deps: [Target.Dependency], settings: [SwiftSetting] = strictSettings) -> Target {
    .testTarget(name: name, dependencies: deps, path: "Tests/\(name)", resources: files[name], swiftSettings: settings)
}
/// The files a test target reads, beside its tests with their provenance (copied whole; `Bundle.module` finds them).
let files: [String: [Resource]] = ["SunsetHostTests": [.copy("Fixtures")]]

let package = Package(
    name: "Sunset",
    platforms: [.macOS(.v26)],
    products: [
        "SunsetCore", "SunsetHost", "SunsetPane", "SunsetShell", "SunsetTerminal", "SunsetWeb", "SunsetConfig",
        "SunsetStorage", "SunsetDocuments", "SunsetQuickLookKit", "SunsetPrivate", "SunsetRender", "SunsetRenderMac",
        "SunsetRenderMetal", "SunsetCredentials"
    ]
    .map { Product.library(name: $0, targets: [$0]) } + [
        .executable(name: "sunset-run", targets: ["SunsetRun"]),
        .executable(name: "sunset-app", targets: ["SunsetAppMain"]),
        .library(name: "SunsetAppLibrary", targets: ["SunsetApp"]),
        .executable(name: "sunset-render", targets: ["SunsetRenderTool"])
    ],
    dependencies: [
        .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "1567137e2c810eb489facf29d90a2c623b75d604"),
        .package(url: "https://github.com/g-cqd/TerminalKit.git", revision: "a777029a43269692cac6485c254ff0c1b438789e"),
        .package(
            url: "https://github.com/g-cqd/AemiMarkdown.git",
            revision: "2240dc9329db6a6770cc60ecf5b14084282c17df"
        ),
        .package(url: "https://github.com/g-cqd/AemiJSON.git", revision: "75deac170071149540c436bdab47a5c6d5520a4a"),
        .package(url: "https://github.com/g-cqd/AemiRegex.git", revision: "792eebdcdf3a47daf8ba6ae9a1dfd4c6c5833fc4"),
        .package(url: "https://github.com/g-cqd/CSVCoder.git", revision: "a2185d4b6d0c208523507b47bcdb4706744d9dd2"),
        .package(
            url: "https://github.com/Aemi-Studio/AemiSDR.git",
            revision: "82dd09653ad654584d42c080ed2f31b7adc75441"
        )
    ],
    targets: [
        .target(
            name: "SunsetCore",
            dependencies: [
                .product(name: "TerminalKitText", package: "TerminalKit"),
                .product(name: "AemiKernel", package: "aemi"),
                .product(name: "AemiRegex", package: "AemiRegex"),
                "CSunsetKernels"
            ],
            path: "Sources/SunsetCore",
            swiftSettings: workSettings
        ),
        .target(
            name: "CSunsetKernels",
            path: "Sources/CSunsetKernels",
            cSettings: workCSettings
        ),
        module("SunsetRender", ["SunsetCore", "CSunsetKernels"], settings: workSettings),
        tests(
            "SunsetRuntimeTests",
            ["SunsetRuntime", .product(name: "AemiTestKit", package: "aemi")]
        ),
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
                "SunsetRuntime", "SunsetAppCore", "SunsetHelp", "SunsetConfig", "SunsetCore", "SunsetHost",
                "SunsetPane",
                "SunsetPrivate", "SunsetRender", "SunsetStorage", "SunsetDocuments", "SunsetRenderMac",
                "SunsetRenderMetal", "SunsetShell", "SunsetShellBridge", "SunsetTerminal", "SunsetWeb",
                "SunsetMarkdown", "SunsetMetrics", "SunsetImport", "SunsetCredentials", "SunsetSiteData",
                "SunsetUpdate", .product(name: "AemiSDR", package: "AemiSDR"),
                .product(name: "MarkdownLookKit", package: "AemiMarkdown")
            ]
        ),
        .executableTarget(
            name: "SunsetRenderTool",
            dependencies: ["SunsetCore", "SunsetHost", "SunsetRender", "SunsetRenderMac"],
            path: "Sources/SunsetRenderTool",
            swiftSettings: strictSettings
        ),
        .target(
            name: "SunsetTestSupport",
            dependencies: ["SunsetRuntime", .product(name: "AemiTestKit", package: "aemi")],
            path: "Tests/SunsetTestSupport",
            swiftSettings: strictSettings
        ),
        module("SunsetRuntime", [.product(name: "AemiRuntime", package: "aemi")]),
        module("SunsetMetrics", []),
        .target(
            name: "SunsetQuickLookKit",
            dependencies: [.product(name: "MarkdownLookKit", package: "AemiMarkdown")],
            path: "Sources/SunsetQuickLookKit"
        ),
        .target(
            name: "SunsetDocuments",
            dependencies: [
                "SunsetRuntime",
                "SunsetStorage", "SunsetHost", .product(name: "MarkdownLookKit", package: "AemiMarkdown"),
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
                .product(name: "MarkdownLookKit", package: "AemiMarkdown"),
                .product(name: "AemiTestKit", package: "aemi")
            ]
        ),
        module("SunsetStorage", ["SunsetRuntime", .product(name: "AemiIO", package: "aemi")]),
        tests("SunsetStorageTests", ["SunsetTestSupport", "SunsetStorage"]),
        module(
            "SunsetCredentials",
            [
                "SunsetStorage", "SunsetRuntime", .product(name: "AemiArgon2", package: "aemi"),
                .product(name: "CSVCoder", package: "CSVCoder"), .product(name: "AemiJSONCore", package: "AemiJSON")
            ]
        ),
        tests(
            "SunsetCredentialsTests",
            [
                "SunsetCredentials", "SunsetStorage", "SunsetTestSupport", "SunsetRuntime",
                .product(name: "AemiTestKit", package: "aemi"), .product(name: "AemiJSON", package: "AemiJSON")
            ]
        ),
        module("SunsetConfig", [.product(name: "AemiJSONCore", package: "AemiJSON"), "SunsetMetrics"]),
        tests("SunsetConfigTests", ["SunsetTestSupport", "SunsetConfig", "SunsetMetrics"]),
        .target(
            name: "SunsetPrivate",
            dependencies: ["SunsetRuntime", .product(name: "InternedStrings", package: "aemi")],
            path: "Sources/SunsetPrivate",
            swiftSettings: strictSettings
        ),
        tests("SunsetPrivateTests", ["SunsetTestSupport", "SunsetPrivate"]),
        module("SunsetPane", []),
        tests("SunsetPaneTests", ["SunsetTestSupport", "SunsetPane"]),
        module("SunsetImport", ["SunsetPane"]),
        tests("SunsetImportTests", ["SunsetImport", "SunsetPane"]),
        module("SunsetHelp", []),
        module("SunsetShellModel", ["SunsetRuntime", "SunsetPane", "SunsetMetrics", "SunsetHelp"]),
        module(
            "SunsetShell",
            [
                "SunsetShellModel", "SunsetRuntime", "SunsetPane", "SunsetMetrics", "SunsetHelp",
                .product(name: "AemiSDR", package: "AemiSDR")
            ]
        ),
        tests(
            "SunsetShellTests",
            [
                "SunsetTestSupport", "SunsetShell", "SunsetShellModel", "SunsetPane", "SunsetMetrics", "SunsetHelp",
                "SunsetConfig", .product(name: "AemiTestKit", package: "aemi")
            ]
        ),
        module(
            "SunsetTerminalModel",
            [
                "SunsetRuntime", "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane", "SunsetRender",
                "SunsetRenderMac", "SunsetRenderMetal", "SunsetShellModel"
            ]
        ),
        module(
            "SunsetTerminal",
            [
                "SunsetTerminalModel", "SunsetRuntime", "SunsetConfig", "SunsetCore", "SunsetHost", "SunsetPane",
                "SunsetRender", "SunsetRenderMac", "SunsetRenderMetal", "SunsetShell", "SunsetMetrics"
            ]
        ),
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
                .product(name: "MarkdownLookKit", package: "AemiMarkdown"),
                .product(name: "AemiTestKit", package: "aemi")
            ]
        ),
        module("SunsetWebModel", ["SunsetRuntime", "SunsetPane", "SunsetShellModel", "SunsetStorage"]),
        .target(
            name: "SunsetSiteData",
            path: "Sources/SunsetSiteData",
            resources: [.copy("Resources")],
            swiftSettings: strictSettings
        ),
        tests("SunsetSiteDataTests", ["SunsetSiteData"]),
        module("SunsetUpdate", []),
        tests("SunsetUpdateTests", ["SunsetUpdate"]),
        .executableTarget(
            name: "SunsetDeltaTool",
            dependencies: ["SunsetUpdate"],
            path: "Sources/SunsetDeltaTool",
            swiftSettings: strictSettings
        ),
        module(
            "SunsetWeb",
            [
                "SunsetWebModel", "SunsetRuntime", "SunsetPane", "SunsetShell", "SunsetPrivate", "SunsetMetrics",
                "SunsetStorage", .product(name: "AemiSDR", package: "AemiSDR")
            ]
        ),
        tests(
            "SunsetWebTests",
            [
                "SunsetTestSupport", "SunsetWeb", "SunsetWebModel", "SunsetPane", "SunsetShell", "SunsetShellModel",
                "SunsetMetrics", "SunsetStorage", .product(name: "AemiTestKit", package: "aemi")
            ]
        ),
        module(
            "SunsetAppCore",
            [
                "SunsetRuntime", "SunsetConfig", "SunsetPane", "SunsetWeb", "SunsetHost", "SunsetShellModel",
                "SunsetStorage", "SunsetDocuments", "SunsetWebModel", "SunsetCredentials"
            ]
        ),
        tests(
            "SunsetAppCoreTests",
            [
                "SunsetTestSupport", "SunsetAppCore", "SunsetConfig", "SunsetPane", "SunsetWeb", "SunsetHost",
                "SunsetShellModel", "SunsetStorage", "SunsetWebModel", "SunsetDocuments", "SunsetCredentials",
                .product(name: "AemiTestKit", package: "aemi")
            ]
        ),
        module("SunsetShellBridge", ["SunsetShell", "SunsetConfig", "SunsetMetrics"]),
        tests(
            "SunsetShellBridgeTests",
            ["SunsetTestSupport", "SunsetShellBridge", "SunsetShell", "SunsetConfig", "SunsetMetrics"]
        ),
        module("SunsetHost", ["SunsetRuntime", "SunsetCore", "SunsetConfig", "SunsetMetrics"]),
        tests(
            "SunsetTerminalTests",
            ["SunsetTerminalModel", "SunsetCore", "SunsetRender", "SunsetConfig", "SunsetRuntime", "SunsetTestSupport"]
        ),
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
        tests(
            "SunsetCoreTests",
            [
                "SunsetTestSupport", .product(name: "AemiTestKit", package: "aemi"), "SunsetCore",
                .product(name: "TerminalKitCodecs", package: "TerminalKit")
            ]
        )
    ]
)
