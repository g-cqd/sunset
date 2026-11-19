// n59 again: the icon macOS serves for an app's path, drawn in the light and the dark appearance (the owner's Mac is
// dark): the system renders an Icon Composer icon's layers per appearance (2026-11-20).
import AppKit

let icon = NSWorkspace.shared.icon(forFile: CommandLine.arguments[1])
for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
    guard let look = NSAppearance(named: appearance) else { continue }
    var png: Data?
    look.performAsCurrentDrawingAppearance {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 256,
            pixelsHigh: 256,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        guard let rep, let context = NSGraphicsContext(bitmapImageRep: rep) else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        icon.draw(in: NSRect(x: 0, y: 0, width: 256, height: 256))
        NSGraphicsContext.restoreGraphicsState()
        png = rep.representation(using: .png, properties: [:])
    }
    try? png?.write(to: URL(fileURLWithPath: CommandLine.arguments[2] + "-\(name).png"))
}
