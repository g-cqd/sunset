// sunset-render: runs a program in a headless Sunset terminal and writes what the CPU renderer draws of its screen as a PNG. A way to look at the renderer
// without a window.
//
//   sunset-render [--cols N] [--rows N] [--font NAME] [--size PT] [--ligatures] [--no-font-ligatures] [--feature TAG[=N]] [--wait MS] [--keys TEXT] [--out FILE] -- command [args...]
internal import Darwin
import SunsetCore
import SunsetHost
import SunsetRender
import SunsetRenderMac

var columns = 80
var rows = 24
var fontName = "Menlo"
var fontSize = 14.0
var waitMilliseconds = 1200
var keys = ""
var ligatures = false
var disableLigatures = false
var features: [FontFeature] = []
var output = "/tmp/sunset-render.png"
var arguments = ToolArguments(Array(CommandLine.arguments.dropFirst()))
while let argument = arguments.next() {
    switch argument {
        case "--cols": columns = arguments.int(or: columns)
        case "--rows": rows = arguments.int(or: rows)
        case "--font": fontName = arguments.value()
        case "--size": fontSize = Double(arguments.value()) ?? fontSize
        case "--wait": waitMilliseconds = arguments.int(or: waitMilliseconds)
        case "--keys": keys = arguments.value()
        case "--ligatures": ligatures = true
        case "--no-font-ligatures": disableLigatures = true
        case "--feature":
            let pair = arguments.value().split(separator: "=")
            features.append(FontFeature(String(pair[0]), pair.count > 1 ? Int(pair[1]) ?? 1 : 1))
        case "--out": output = arguments.value()
        default: arguments.commandStarts(with: argument)
    }
}
let command = arguments.command
guard !command.isEmpty else {
    print(
        "usage: sunset-render [--cols N] [--rows N] [--font NAME] [--size PT] [--ligatures] [--no-font-ligatures] [--feature TAG[=N]] [--wait MS] [--keys TEXT] [--out FILE] -- command [args...]"
    )
    exit(2)
}

do {
    let glyphs = CoreTextGlyphSource(
        fontName: fontName,
        size: fontSize,
        features: features,
        ligatures: !disableLigatures
    )
    var metrics = glyphs.metrics
    metrics.paddingX = 8
    metrics.paddingY = 8
    // The program is told a cell's size in pixels from the start, as image tools ask it.
    let session = try HeadlessSession(
        command,
        columns: columns,
        rows: rows,
        cell: (metrics.cellWidth, metrics.cellHeight)
    )
    _ = session.wait(timeoutMilliseconds: waitMilliseconds) { _ in false }
    if !keys.isEmpty {
        try session.send(KeyText.unescape(keys))
        _ = session.wait(timeoutMilliseconds: 500) { _ in false }
    }
    let size = metrics.surfaceSize(columns: columns, rows: rows)
    var surface = Surface(width: size.width, height: size.height)
    let renderer = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures, images: ImageIODecoder())
    renderer.render(session.terminal.screen, into: &surface)
    let bytes = PNG.encode(surface)
    guard let file = fopen(output, "wb") else {
        print("cannot write \(output)")
        exit(1)
    }
    _ = bytes.withUnsafeBufferPointer { fwrite($0.baseAddress, 1, $0.count, file) }
    fclose(file)
    print(
        "wrote \(output): \(size.width)x\(size.height) pixels, cell \(metrics.cellWidth)x\(metrics.cellHeight), font \(fontName) \(fontSize)"
    )
} catch {
    print("failed: \(error)")
    exit(1)
}
