// Measures the system's controls off-screen (design 0003 §9): each control is drawn into a 2x bitmap, never into a window on screen; its
// height comes from AppKit, its corner from the pixels (rows from the bezel's top until its left edge stops moving inward).
// Run: swift docs/research/probes/system-controls.swift
import AppKit

@MainActor func measure(_ view: NSView, _ name: String) {
    view.appearance = NSAppearance(named: .darkAqua)
    let size = view.fittingSize
    view.frame = NSRect(x: 0, y: 0, width: max(size.width, 120), height: size.height)
    view.layoutSubtreeIfNeeded()
    let scale = 2
    guard
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(view.frame.width) * scale,
            pixelsHigh: Int(view.frame.height) * scale,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else { return }
    rep.size = view.frame.size
    view.cacheDisplay(in: view.bounds, to: rep)
    // The bezel: pixels whose alpha is over a quarter. Its top row, and the leftmost bezel pixel on each row from there.
    func alpha(_ x: Int, _ y: Int) -> Double { Double(rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) }
    let w = rep.pixelsWide
    let h = rep.pixelsHigh
    let rows = (0 ..< h).filter { y in (0 ..< w).contains { alpha($0, y) > 0.25 } }
    guard let top = rows.first, let bottom = rows.last else { return print("\(name): nothing drawn") }
    let left = { (y: Int) in (0 ..< w).first { alpha($0, y) > 0.25 } ?? w }
    let straight = (top ... bottom).map(left).min() ?? 0
    let cornerRows = (top ... bottom).first { left($0) <= straight }.map { $0 - top } ?? 0
    let bezelHeight = Double(bottom - top + 1) / Double(scale)
    print(
        String(
            format: "%@: fitting height %.1f, bezel height %.1f, corner extent %.1f pt",
            name,
            size.height,
            bezelHeight,
            Double(cornerRows) / Double(scale)
        )
    )
}

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let sizes: [(String, NSControl.ControlSize)] = [
        ("mini", .mini), ("small", .small), ("regular", .regular), ("large", .large),
        ("extraLarge", .extraLarge)
    ]
    for (label, controlSize) in sizes {
        let button = NSButton(title: "Button", target: nil, action: nil)
        button.bezelStyle = .push
        button.controlSize = controlSize
        measure(button, "push button, \(label)")
    }
    for (label, controlSize) in sizes {
        let field = NSTextField(string: "Field")
        field.bezelStyle = .roundedBezel
        field.controlSize = controlSize
        measure(field, "rounded field, \(label)")
    }
    for (label, controlSize) in sizes {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.addItem(withTitle: "Choice")
        popup.controlSize = controlSize
        measure(popup, "pop-up, \(label)")
    }
}
