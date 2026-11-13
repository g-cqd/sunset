import SwiftUI

/// The look of `TabCapsuleButton`.
struct TabCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TabCapsuleButtonFace(label: configuration.label, pressed: configuration.isPressed)
    }
}
