import AppKit

/// A menu item that runs a closure (the puzzle piece's list of extensions).
final class ClosureMenuItem: NSMenuItem {
    private let run: () -> Void

    init(title: String, run: @escaping () -> Void) {
        self.run = run
        super.init(title: title, action: #selector(fire), keyEquivalent: "")
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("not from a nib")
    }

    @objc private func fire() {
        run()
    }
}
