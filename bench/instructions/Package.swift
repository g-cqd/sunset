// swift-tools-version: 6.2
import PackageDescription

// Feeds a stream to a headless terminal many times, to be counted in instructions (bench/instructions/run.sh): the count does not move with the
// machine's load, which wall times do.
let package = Package(
    name: "instructions",
    platforms: [.macOS(.v26)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(name: "instructions", dependencies: [.product(name: "SunsetCore", package: "sunset")])
    ]
)
