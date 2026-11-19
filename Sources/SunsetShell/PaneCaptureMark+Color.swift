package import SwiftUI

extension PaneCaptureMark {
    /// Red for the camera or the microphone, orange for a screen, as macOS marks them.
    package var color: Color {
        switch self {
            case .cameraOrMicrophone: .red
            case .screen: .orange
        }
    }
}
