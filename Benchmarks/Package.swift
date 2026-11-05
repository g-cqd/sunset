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
let probeSettings: [SwiftSetting] = [.swiftLanguageMode(.v6)]

let package = Package(
    name: "benchmarks",
    platforms: [.macOS(.v26)],
    dependencies: [
        // Exact, like every other pin in the ecosystem: a harness that moves under the numbers changes the numbers.
        .package(url: "https://github.com/ordo-one/benchmark", exact: "1.38.0")
    ],
    targets: [
        .target(
            name: "BenchmarkSupport",
            dependencies: [.product(name: "Benchmark", package: "benchmark")],
            path: "Sources/BenchmarkSupport",
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "VTModelBenchmarks",
            dependencies: [.product(name: "Benchmark", package: "benchmark"), "BenchmarkSupport"],
            path: "Benchmarks/VTModelBenchmarks",
            swiftSettings: probeSettings,
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        )
    ]
)
