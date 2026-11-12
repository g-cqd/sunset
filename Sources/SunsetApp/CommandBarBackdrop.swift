import AemiSDR
import SunsetShell
import SwiftUI

/// Behind the command bar, over the window: a soft, darker blur of the window (`appearance.barBlur` variable), else the dark veil.
struct CommandBarBackdrop: View {
    @Environment(\.barBlur) private var choice

    var body: some View {
        if choice == .variable {
            BlurBackdropView(Design.Blur.commandBackdrop, groupName: Design.Blur.group)
        } else {
            Color.black.opacity(Design.Fill.backdrop)
        }
    }
}
