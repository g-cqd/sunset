/// The part of an image a placement shows, in the image's pixels (kitty's `x`, `y`, `w`, `h`).
struct ImageCrop: Hashable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}
