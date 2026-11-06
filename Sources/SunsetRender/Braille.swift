/// U+2800...U+28FF: eight dots in two columns of four. Each dot is a square about a quarter of the cell wide, centred in its quarter.
enum Braille {
    static func draw(_ scalar: UInt32, into canvas: inout Canvas) {
        let bits = Int(scalar - 0x2800)
        // Dot bit -> (column, row): 1,2,3 down the left, 4,5,6 down the right, 7 and 8 the bottom row.
        let places: [(column: Int, row: Int)] = [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (0, 3), (1, 3)]
        let size = max(1, min(canvas.width / 4, canvas.height / 8))
        for (index, place) in places.enumerated() where bits & (1 << index) != 0 {
            let centerX = (canvas.width * (2 * place.column + 1)) / 4
            let centerY = (canvas.height * (2 * place.row + 1)) / 8
            canvas.fill(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size)
        }
    }
}
