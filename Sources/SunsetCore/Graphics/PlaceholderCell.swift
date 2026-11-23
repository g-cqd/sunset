/// What one placeholder cell says (roadmap 0010 E): the image and placement it draws, and which of the image's virtual cells it
/// is: its row, its column, and the image id's highest byte.
struct PlaceholderCell: Equatable {
    let image: UInt32
    let placement: UInt32
    let row: Int
    let column: Int
    let high: UInt32

    /// The whole image id: the highest byte above the colour's 24 bits.
    var id: UInt32 {
        high << 24 | image
    }
}
