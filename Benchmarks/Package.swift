// swift-tools-version: 6.4
import PackageDescription

// Sunset's benchmarks, on ordo-one's package-benchmark (ADR-0018), as TerminalKit does (its roadmap 0006 and ADR-0017).
//
// A separate package so the shipping graph never resolves the framework. Release only.
//   Run:      Scripts/benchmarks.sh                 (add --contend to hold the standard contention profile, ADR-0017)
//   Compare:  Scripts/benchmarks.sh compare <rev>
//   Gate:     instructions and allocations exactly, wall clock on its 25th percentile (Sources/BenchmarkSupport/Thresholds.swift)
//
// `VTModelBenchmarks` is research code (a throwaway headless VT model, sunset roadmap 0002 probe T0.4): it uses unsafe pointers on
// purpose, so it builds without StrictMemorySafety. Real targets use the white paper's strict settings.
let strictSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("StrictMemorySafety"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error)
]
// -cross-module-optimization: without it the generic Model<C> is not specialised across the module boundary and costs 7x the instructions (diary 2026-11-05-01).
let probeSettings: [SwiftSetting] = [.swiftLanguageMode(.v6), .unsafeFlags(["-cross-module-optimization"])]

let package = Package(
    name: "benchmarks",
    platforms: [.macOS(.v26)],
    dependencies: [
        // Exact, like every other pin in the ecosystem: a harness that moves under the numbers changes the numbers.
        .package(url: "https://github.com/ordo-one/benchmark", exact: "1.38.0"),
        .package(name: "Sunset", path: "..")
    ],
    targets: [
        .target(
            name: "BenchmarkSupport",
            dependencies: [.product(name: "Benchmark", package: "benchmark")],
            path: "Sources/BenchmarkSupport",
            swiftSettings: strictSettings
        ),
        .target(name: "VTModel", path: "Sources/VTModel", swiftSettings: probeSettings),
        .executableTarget(
            name: "VTModelBenchmarks",
            dependencies: [.product(name: "Benchmark", package: "benchmark"), "BenchmarkSupport", "VTModel"],
            path: "Benchmarks/VTModelBenchmarks",
            swiftSettings: probeSettings,
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        // The real parser (roadmap 0003), strict settings.
        .executableTarget(
            name: "ParserBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"), "BenchmarkSupport",
                .product(name: "SunsetCore", package: "Sunset")
            ],
            path: "Benchmarks/ParserBenchmarks",
            swiftSettings: strictSettings,
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        // Not a benchmark: who holds the screen when a renderer wants a frame (sunset roadmap 0002 probe T0.3, ADR-0014).
        // Not a benchmark: GPU reads the screen's cells vs CPU-rebuilt instances (sunset roadmap 0002 probe T0.5, ADR-0015).
        .executableTarget(name: "MetalProbe", path: "Probes/MetalProbe", swiftSettings: probeSettings),
        // Not a benchmark: bytes per cell of cold history, structural encoding vs the platform's compressors, on real text (sunset roadmap 0002 probes T0.2).
        .executableTarget(
            name: "ColdHistoryProbe",
            dependencies: ["VTModel"],
            path: "Probes/ColdHistoryProbe",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "HandoffProbe",
            dependencies: ["VTModel"],
            path: "Probes/HandoffProbe",
            swiftSettings: probeSettings
        )
    ]
)
