import AppKit
import SunsetShellModel
import SunsetWeb

/// "Add “Name”?" with what it may do, as Safari asks (all or nothing). Cancel is the default: Return does not install,
/// a click on "Add Extension" does. In Sunset's look.
enum ExtensionPrompt {
    @MainActor static func ask(_ candidate: ExtensionHost.Candidate) async -> Bool {
        let lines = candidate.lines
        let what =
            lines.isEmpty
            ? "It asks for nothing more than its own storage."
            : "It will be able to:\n" + lines.map { "\u{2022} " + $0 }.joined(separator: "\n")
        let png = candidate.icon.flatMap { $0.tiffRepresentation }.flatMap { NSBitmapImageRep(data: $0) }
            .flatMap { $0.representation(using: .png, properties: [:]) }
        let alert = SunsetAlert(
            title: "Add \u{201C}\(candidate.name)\u{201D}?",
            message: [candidate.summary, what].filter { !$0.isEmpty }.joined(separator: "\n\n"),
            icon: png.map { [UInt8]($0) },
            buttons: [.cancel("Cancel"), .plain("Add Extension")],
            defaultButton: 0
        )
        return await SunsetAlerts.ask(alert) == 1
    }
}
