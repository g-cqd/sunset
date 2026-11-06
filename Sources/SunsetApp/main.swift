// Sunset: a terminal in a window. This is the first app shell (roadmap 0009): one window, one program, the CPU renderer, keys and paste. No tabs,
// selection, mouse, search, settings or theme yet.
//
//   sunset-app [--font NAME] [--size PT] [--ligatures] [--feature TAG[=N]] [-- command [args...]]
import AppKit
import SunsetRenderMac

var fontName = "Menlo"
var fontSize = 14.0
var ligatures = false
var features: [FontFeature] = []
var command: [String] = []
var arguments = Array(CommandLine.arguments.dropFirst())
while let argument = arguments.first {
    arguments.removeFirst()
    switch argument {
        case "--font": fontName = arguments.removeFirst()
        case "--size": fontSize = Double(arguments.removeFirst()) ?? fontSize
        case "--ligatures": ligatures = true
        case "--feature":
            let pair = arguments.removeFirst().split(separator: "=")
            features.append(FontFeature(String(pair[0]), pair.count > 1 ? Int(pair[1]) ?? 1 : 1))
        case "--":
            command = arguments
            arguments = []
        default:
            command = [argument] + arguments
            arguments = []
    }
}
if command.isEmpty {
    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    command = [shell, "-l"]
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        var environment = ProcessInfo.processInfo.environment
        environment["TERM_PROGRAM"] = "sunset"
        environment["COLORTERM"] = "truecolor"
        environment["TERM"] = "xterm-256color"
        do {
            let view = try TerminalView(
                command: command,
                environment: environment,
                fontName: fontName,
                fontSize: fontSize,
                features: features,
                ligatures: ligatures
            )
            let window = NSWindow(
                contentRect: NSRect(x: 200, y: 200, width: 820, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Sunset"
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            view.onTitle = { window.title = $0.isEmpty ? "Sunset" : $0 }
            view.onExit = { NSApp.terminate(nil) }
            self.window = window
        } catch {
            NSLog("sunset: cannot start \(command): \(error)")
            NSApp.terminate(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let application = NSApplication.shared
application.setActivationPolicy(.regular)
let delegate = AppDelegate()
application.delegate = delegate

let mainMenu = NSMenu()
let appItem = NSMenuItem()
mainMenu.addItem(appItem)
let appMenu = NSMenu()
appMenu.addItem(NSMenuItem(title: "Quit Sunset", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
appItem.submenu = appMenu
let editItem = NSMenuItem()
mainMenu.addItem(editItem)
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(NSMenuItem(title: "Paste", action: Selector(("paste:")), keyEquivalent: "v"))
editItem.submenu = editMenu
application.mainMenu = mainMenu
application.run()
