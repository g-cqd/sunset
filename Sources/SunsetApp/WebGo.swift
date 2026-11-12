import Foundation
import SunsetPane
import SunsetShell
import SunsetWeb

/// Opens an address or a search from the command bar: in the focused page, in a new page tab, or in a page split beside what is focused.
@MainActor enum WebGo {
    enum Place { case here, newTab, splitRight }

    static func open(_ input: WebInput, in tabs: TabsModel, place: Place) {
        guard let url = input.url else { return }
        let descriptor = PaneDescriptor(kind: WebContent.kind, state: ["url": url.absoluteString])
        switch place {
            case .here:
                guard let page = tabs.selectedContent as? WebContent else {
                    return open(input, in: tabs, place: .newTab)
                }
                page.open(input)
                page.focusPage()
            case .newTab:
                tabs.newTab(descriptor)
            case .splitRight:
                guard let shown = tabs.selectedContent else { return open(input, in: tabs, place: .newTab) }
                tabs.split(.right, with: tabs.makeContent(descriptor), beside: shown)
        }
    }
}
