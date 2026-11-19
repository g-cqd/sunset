// n59: the icon macOS serves for an app's path (NSWorkspace, from Icon Services' cache), drawn to a PNG (2026-11-19).
import AppKit

let icon = NSWorkspace.shared.icon(forFile: CommandLine.arguments[1])
let rendered = NSImage(size: NSSize(width: 128, height: 128), flipped: false) { rect in
    icon.draw(in: rect)
    return true
}
if let tiff = rendered.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
{
    try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
}
