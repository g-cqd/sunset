// sunset-render: runs a program in a headless Sunset terminal and writes what the CPU renderer draws of its screen as a PNG. A way to look at the renderer
// without a window (roadmap 0008).
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
var command: [String] = []
var arguments = Array(CommandLine.arguments.dropFirst())
while let argument = arguments.first {
    arguments.removeFirst()
    switch argument {
        case "--cols": columns = Int(arguments.removeFirst()) ?? columns
        case "--rows": rows = Int(arguments.removeFirst()) ?? rows
        case "--font": fontName = arguments.removeFirst()
        case "--size": fontSize = Double(arguments.removeFirst()) ?? fontSize
        case "--wait": waitMilliseconds = Int(arguments.removeFirst()) ?? waitMilliseconds
        case "--keys": keys = arguments.removeFirst()
        case "--ligatures": ligatures = true
        case "--no-font-ligatures": disableLigatures = true
        case "--feature":
            let pair = arguments.removeFirst().split(separator: "=")
            features.append(FontFeature(String(pair[0]), pair.count > 1 ? Int(pair[1]) ?? 1 : 1))
        case "--out": output = arguments.removeFirst()
        case "--":
            command = arguments
            arguments = []
        default:
            command = [argument] + arguments
            arguments = []
    }
}
guard !command.isEmpty else {
    print(
        "usage: sunset-render [--cols N] [--rows N] [--font NAME] [--size PT] [--ligatures] [--no-font-ligatures] [--feature TAG[=N]] [--wait MS] [--keys TEXT] [--out FILE] -- command [args...]"
    )
    exit(2)
}

func unescape(_ text: String) -> String {
    var result = ""
    var iterator = text.makeIterator()
    while let character = iterator.next() {
        guard character == "\\", let next = iterator.next() else {
            result.append(character)
            continue
        }
        switch next {
            case "e": result.append("\u{1B}")
            case "n": result.append("\n")
            case "r": result.append("\r")
            case "t": result.append("\t")
            default: result.append(next)
        }
    }
    return result
}

do {
    let session = try HeadlessSession(command, columns: columns, rows: rows)
    _ = session.wait(timeoutMilliseconds: waitMilliseconds) { _ in false }
    if !keys.isEmpty {
        try session.send(unescape(keys))
        _ = session.wait(timeoutMilliseconds: 500) { _ in false }
    }
    let glyphs = CoreTextGlyphSource(
        fontName: fontName,
        size: fontSize,
        features: features,
        ligatures: !disableLigatures
    )
    var metrics = glyphs.metrics
    metrics.paddingX = 8
    metrics.paddingY = 8
    let size = metrics.surfaceSize(columns: columns, rows: rows)
    var surface = Surface(width: size.width, height: size.height)
    let renderer = CPURenderer(metrics: metrics, glyphs: glyphs, ligatures: ligatures)
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
