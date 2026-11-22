/// An image placement on the lines a frame shows, ready to draw: image `number` of the renderer's table, from pixel `x`, from
/// the line `top` (counted from the oldest of the history) and `offsetY` pixels into it, `width` × `height` of it shown
/// (clipped to its `rows` of cells), in its `layer`.
struct ShownImage {
    let number: UInt32
    let x: Int
    let top: Int
    let offsetY: Int
    let rows: Int
    let width: Int
    let height: Int
    let layer: ImageLayer
}
