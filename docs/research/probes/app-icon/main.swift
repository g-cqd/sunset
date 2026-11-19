// n59: whether the app's alternate icons load by name from its own asset catalog, as `applyIcon()` asks for them
// (`NSImage(named:)` in the app; here `Bundle.image(forResource:)` on the installed bundle), and what they look like (2026-11-19).
import AppKit

let app = URL(fileURLWithPath: CommandLine.arguments[1])
let out = URL(fileURLWithPath: CommandLine.arguments[2])
guard let bundle = Bundle(url: app) else { exit(1) }
for name in ["Sunset", "Twilight", "Dawn", "Dusk"] {
    guard let image = bundle.image(forResource: name) else {
        print(name, "-> nil")
        continue
    }
    let reps = image.representations.map { "\(type(of: $0)) \(Int($0.pixelsWide))px" }
    print(name, "-> size", image.size, "reps", reps.prefix(4))
    let size = NSSize(width: 128, height: 128)
    let rendered = NSImage(size: size, flipped: false) { rect in
        image.draw(in: rect)
        return true
    }
    if let tiff = rendered.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    {
        try? png.write(to: out.appending(path: "\(name).png"))
    }
}
