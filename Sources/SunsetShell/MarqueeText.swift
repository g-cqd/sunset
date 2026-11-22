package import AppKit
package import SwiftUI

/// One line of text that scrolls when it is longer than its room (`MarqueeTextView`): a Now Playing card's title.
package struct MarqueeText: NSViewRepresentable {
    let text: String
    let font: NSFont

    package init(_ text: String, font: NSFont = .preferredFont(forTextStyle: .body)) {
        self.text = text
        self.font = font
    }

    package func makeNSView(context: Context) -> NSView {
        let view = MarqueeTextView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    package func updateNSView(_ view: NSView, context: Context) {
        guard let view = view as? MarqueeTextView else { return }
        view.font = font
        view.text = text
    }

    package func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: nsView.intrinsicContentSize.height)
    }
}
