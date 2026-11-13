import AemiSDR
import SwiftUI

/// The look of `View.barGroupBlurs()`: the blurs of the bar groups inside, all beneath all of them.
struct BarGroupBlurs: ViewModifier {
    @Environment(\.barBlur) private var choice

    /// A group inside: where it is, and its blur's margin and edge.
    struct Entry {
        let bounds: Anchor<CGRect>
        let margin: Double
        let top: Bool
    }

    struct Key: PreferenceKey {
        static let defaultValue: [Entry] = []
        static func reduce(value: inout [Entry], nextValue: () -> [Entry]) { value += nextValue() }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.barGroupBlursBelow, true)
            .backgroundPreferenceValue(Key.self) { entries in
                if choice == .variable {
                    GeometryReader { proxy in
                        ZStack(alignment: .topLeading) {
                            ForEach(entries.indices, id: \.self) { index in
                                blur(entries[index], in: proxy)
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
    }

    private func blur(_ entry: Entry, in proxy: GeometryProxy) -> some View {
        let outsets = BarGroup.outsets(margin: entry.margin, top: entry.top)
        let rect = proxy[entry.bounds]
        let size = CGSize(
            width: rect.width + outsets.leading + outsets.trailing,
            height: rect.height + outsets.top + outsets.bottom
        )
        return BlurBackdropView(Design.Blur.group(size: size, margin: entry.margin, top: entry.top))
            .frame(width: size.width, height: size.height)
            .offset(x: rect.minX - outsets.leading, y: rect.minY - outsets.top)
    }
}
