import SunsetCore
import Testing

@testable import SunsetRender

struct RunShapingRig {
    var terminal: Terminal
    var surface: Surface
    let renderer: CPURenderer
    let source: RunShapingSource

    init(ligatures: Bool, columns: Int = 40) {
        source = RunShapingSource()
        terminal = Terminal(columns: columns, rows: 3)
        let size = metrics.surfaceSize(columns: columns, rows: 3)
        surface = Surface(width: size.width, height: size.height)
        renderer = CPURenderer(metrics: metrics, glyphs: source, ligatures: ligatures)
    }

    mutating func frame(_ text: String, cursorVisible: Bool = false) {
        terminal.feed(text)
        renderer.render(terminal.screen, into: &surface, cursorVisible: cursorVisible)
        terminal.clearDirty()
    }

    func pixel(_ column: Int, _ x: Int, _ y: Int, row: Int = 0) -> RGB { surface[column * 8 + x, row * 16 + y] }
}
