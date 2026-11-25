import AppKit

/// Printable emergency sheet showing the vault's recovery code and a scannable QR code (roadmap 0095 B).
final class EmergencySheetView: NSView {
    private let vaultName: String
    private let recoveryCode: String
    private let qr: NSImage?

    init(vaultName: String, recoveryCode: String, qr: NSImage?) {
        self.vaultName = vaultName
        self.recoveryCode = recoveryCode
        self.qr = qr
        super.init(frame: NSRect(x: 0, y: 0, width: 540, height: 700))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        dirtyRect.fill()

        let margin: CGFloat = 48
        let width = bounds.width - margin * 2
        var y: CGFloat = 56

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.darkGray
        ]
        let codeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.black
        ]

        ("Sunset Vault Emergency Sheet" as NSString).draw(at: NSPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 34
        ("Vault: \(vaultName)" as NSString).draw(at: NSPoint(x: margin, y: y), withAttributes: subAttrs)
        y += 28

        let guidance =
            "Keep this sheet in a safe offline place. Anyone holding this recovery code can unlock your vault "
            + "and any sealed .svault backup without your master password or Touch ID."
        let guidanceRect = NSRect(x: margin, y: y, width: width, height: 64)
        (guidance as NSString).draw(in: guidanceRect, withAttributes: subAttrs)
        y += 72

        let codeRect = NSRect(x: margin, y: y, width: width, height: 56)
        (recoveryCode as NSString).draw(in: codeRect, withAttributes: codeAttrs)
        y += 76

        if let qr {
            let side: CGFloat = 200
            qr.draw(in: NSRect(x: margin, y: y, width: side, height: side))
        }
    }
}
