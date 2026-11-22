/// The part of an image a placement shows (`x`, `y`, `w`, `h`, in the image's pixels) and where it starts within its first
/// cell (`X`, `Y`).
struct ImagePart {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let offsetX: Int
    let offsetY: Int
}
