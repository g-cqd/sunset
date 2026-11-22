import AppKit
import SunsetConfig

extension Configuration.MaterialThickness {
    /// The system's behind-window material of this thickness. macOS names its materials by use, not thickness: these
    /// were ordered by how much of a white, blue, black and lettered backdrop showed through each, in a dark window, on
    /// 2026-11-18. Regular is what the window and the sidebar had before.
    func systemMaterial(sidebar: Bool) -> NSVisualEffectView.Material {
        switch self {
            case .ultraThin: .hudWindow
            case .thin: .popover
            case .regular: sidebar ? .sidebar : .underWindowBackground
            case .thick: .headerView
            case .ultraThick: .windowBackground
        }
    }
}
