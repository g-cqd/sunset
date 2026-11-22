/// Where an image is drawn among a row's backgrounds and text, as kitty does by its `z`: over the text (0 or more); under
/// the text but over the cells' own backgrounds (negative); under those too (below −1,073,741,824).
enum ImageLayer {
    case underBackgrounds, underText, overText

    init(z: Int) {
        self = z >= 0 ? .overText : z < -1_073_741_824 ? .underBackgrounds : .underText
    }
}
