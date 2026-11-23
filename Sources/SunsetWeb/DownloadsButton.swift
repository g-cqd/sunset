package import SunsetRuntime
import SunsetShell
package import SwiftUI

/// The downloads button at the bottom of the sidebar: a ring while something downloads; the pointer on it shows the latest download as a
/// card; a click opens the list, which stays until dismissed. One popover shows either.
package struct DownloadsButton: View {
    @Environment(\.runtime) var runtime

    private enum Shown { case card, list }

    @State private var shown: Shown?
    @State private var resting: Task<Void, Never>?
    /// The finished downloads the button has shown its check for (n137): below `finishedCount`, it shows one.
    @State private var acknowledged: Int?
    @State private var settling: Task<Void, Never>?
    private let center = DownloadCenter.shared

    package init() {}

    /// A download finished since the check was last put away, and none runs.
    private var showsDone: Bool {
        center.running.isEmpty && center.finishedCount > (acknowledged ?? center.finishedCount)
    }

    package var body: some View {
        SidebarIconButton(help: "Downloads") {
            resting?.cancel()
            shown = shown == .list ? nil : .list
        } label: {
            DownloadRing(fraction: center.progress, running: !center.running.isEmpty, done: showsDone)
        }
        .onAppear { acknowledged = acknowledged ?? center.finishedCount }
        .onChange(of: center.finishedCount) { _, count in
            // A check for a few seconds, from the same frame the ring stops (it flashed full before), then the arrow again.
            settling?.cancel()
            settling = runtime.task { @MainActor in
                guard await runtime.sleep(for: DownloadRing.doneFor) else { return }
                acknowledged = count
            }
        }
        .onHover { inside in
            resting?.cancel()
            if inside {
                // The card comes after the pointer rests a moment, so that a click opens the list at once.
                resting = runtime.task { @MainActor in
                    await runtime.sleep(for: .milliseconds(600))
                    if !Task.isCancelled, shown == nil, center.latest != nil { shown = .card }
                }
            } else if shown == .card {
                shown = nil
            }
        }
        .popover(isPresented: Binding(get: { shown != nil }, set: { if !$0 { shown = nil } }), arrowEdge: .top) {
            Group {
                if shown == .list {
                    DownloadsList(center: center)
                } else if let latest = center.latest {
                    DownloadCard(item: latest)
                }
            }
            .solidPopoverBackground()
        }
    }
}
