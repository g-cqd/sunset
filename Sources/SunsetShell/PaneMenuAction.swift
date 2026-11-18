/// One item a pane's content adds to its tab's menu (roadmap 0047 G).
package struct PaneMenuAction {
    package let title: String
    package let run: @MainActor () -> Void

    package init(_ title: String, run: @escaping @MainActor () -> Void) {
        self.title = title
        self.run = run
    }
}
