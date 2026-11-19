import AppKit
import SunsetCore

/// The question before a risky paste (task t116): a sheet on the terminal's window naming each risk and showing the text as
/// it would be sent. Cancel is the default: Return does not paste.
@MainActor
enum PasteWarning {
    static func ask(_ risks: [PasteRisk], _ text: String, in window: NSWindow?, paste: @escaping @MainActor () -> Void)
    {
        let alert = NSAlert()
        alert.messageText = PasteRisk.title(of: risks)
        alert.informativeText = risks.map(\.sentence).joined(separator: "\n\n")
        let preview = NSTextField(wrappingLabelWithString: PasteRisk.preview(text))
        preview.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        preview.preferredMaxLayoutWidth = 360
        preview.frame.size = preview.fittingSize
        alert.accessoryView = preview
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Paste")
        let answer: (NSApplication.ModalResponse) -> Void = { response in
            if response == .alertSecondButtonReturn { paste() }
        }
        if let window {
            alert.beginSheetModal(for: window, completionHandler: answer)
        } else {
            answer(alert.runModal())
        }
    }
}
