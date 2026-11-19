import AppKit
import SunsetConfig
import SunsetHost
import SunsetMarkdown
import SunsetPane
import SunsetPrivate
import SunsetRender
import SunsetShell
import SunsetShellBridge
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// The window's settings given to its terminals.
extension TerminalScene {
    func configure(_ model: TerminalModel) {
        model.blinkSchedule = blinkSchedule
        model.defaultColors = colors
        model.paddingPoints = configuration.terminalPadding
        model.backgroundAlpha = configuration.backgroundAlpha
        model.scroll = configuration.scroll
        model.rendererChoice = configuration.renderer
        model.applyLayout()
    }

    func forEachModel(_ body: (TerminalModel) -> Void) {
        for model in tabs.allTerminals { body(model) }
    }
}
