// swift-tools-version: 6.2
import PackageDescription

/// A driver for apps through the accessibility API, for testing Sunset without taking the screen: elements are found by ranked search, pressed,
/// filled, their menus used, keys sent to the process, windows captured; all while the app stays in the background.
let package = Package(
    name: "axdrive",
    platforms: [.macOS(.v26)],
    targets: [.executableTarget(name: "axdrive", path: "Sources/axdrive")]
)
