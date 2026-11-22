import SunsetRuntime
import SunsetShell
import SunsetWeb
import SwiftUI

/// Whether pages go through the proxy: checked by itself a moment after the proxy changes, and again on demand
/// (`ProxyCheck`: Apple's captive-network page, through the proxy as pages are; nothing else is asked).
struct ProxyCheckRow: View {
    @Environment(\.runtime) var runtime

    let address: String
    let title: String
    @State private var outcome: ProxyCheck.Outcome?
    @State private var checking = false

    var body: some View {
        LabeledContent {
            HStack(spacing: Design.Space.m) {
                if checking { ProgressView().controlSize(.small) }
                Button("Check Again") { runtime.task { await check() } }
                    .disabled(checking || WebProxy(address) == nil)
            }
        } label: {
            SettingsLabel(title)
            Text(Self.sentence(outcome, address: address, checking: checking))
                .foregroundStyle(outcome == .throughProxy ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange))
        }
        // A moment after it is typed: not at each keystroke.
        .task(id: address) {
            await runtime.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await check()
        }
    }

    private func check() async {
        checking = true
        outcome = await ProxyCheck.run(WebProxy(address))
        checking = false
    }

    static func sentence(_ outcome: ProxyCheck.Outcome?, address: String, checking: Bool) -> String {
        if checking { return "Checking\u{2026}" }
        switch outcome {
            case nil, .noProxy?:
                return address.isEmpty ? "No proxy is set." : "Not a proxy Sunset reads."
            case .throughProxy?: return "Yes: a page asked through it was answered by way of it."
            case .notThroughProxy?: return "No: the page was answered, but not by way of the proxy."
            case .failed(let reason)?: return "No: \(reason)"
        }
    }
}
