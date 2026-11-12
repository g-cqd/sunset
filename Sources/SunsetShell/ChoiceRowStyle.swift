import SwiftUI

/// The fills of a choice row: the accent for the keyboard's row; else darker while pressed, lighter under the pointer.
struct ChoiceRowStyle: ButtonStyle {
    let selected: Bool
    let radius: Double

    func makeBody(configuration: Configuration) -> some View {
        ChoiceRowFill(label: configuration.label, pressed: configuration.isPressed, selected: selected, radius: radius)
    }
}
