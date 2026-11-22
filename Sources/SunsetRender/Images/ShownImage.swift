/// An image placement on the lines a frame shows, ready to draw: image `number` of the renderer's table, from pixel `x`, from
/// the line `top` (counted from the oldest of the history) down `rows` lines, `width` × `height` of it shown (clipped to its
/// cells), above the text or below it (`layer`).
struct ShownImage {
    let number: UInt32
    let x: Int
    let top: Int
    let rows: Int
    let width: Int
    let height: Int
    let layer: Int
}
