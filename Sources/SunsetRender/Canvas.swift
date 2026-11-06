/// A coverage canvas with rectangle and anti-aliased line helpers.
struct Canvas {
    let width: Int
    let height: Int
    var coverage: [UInt8]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        coverage = [UInt8](repeating: 0, count: width * height)
    }

    /// Fills the rectangle [x, x + w) x [y, y + h), clipped, with `value` (the larger of it and what is there).
    mutating func fill(x: Int, y: Int, width w: Int, height h: Int, value: UInt8 = 255) {
        let x0 = max(0, x)
        let x1 = min(width, x + w)
        let y0 = max(0, y)
        let y1 = min(height, y + h)
        guard x0 < x1, y0 < y1 else { return }
        for row in y0 ..< y1 {
            for column in x0 ..< x1 { coverage[row * width + column] = max(coverage[row * width + column], value) }
        }
    }

    mutating func plot(x: Int, y: Int, value: UInt8) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        coverage[y * width + x] = max(coverage[y * width + x], value)
    }
}
