import AemiSDR
package import SwiftUI

/// A bar over the page at a window's edge (roadmap 0055; the owner's notes n41, n42): the page keeps the whole height under
/// it. Hidden, it comes out when the pointer reaches the edge and goes a moment after the pointer leaves it, never while it
/// is typed in (`EdgeReveal`); kept shown, it is always out, the fading blur under it.
package struct FloatingEdgeBar<Content: View>: View {
    let atTop: Bool
    let hides: Bool
    let typing: Bool
    @ViewBuilder let content: () -> Content
    @State private var reveal: EdgeReveal
    @Environment(\.barTint) private var tint
    @Environment(\.colorScheme) private var outer

    package init(atTop: Bool, hides: Bool, typing: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.atTop = atTop
        self.hides = hides
        self.typing = typing
        self.content = content
        _reveal = State(initialValue: EdgeReveal(hides: hides))
    }

    package var body: some View {
        ZStack(alignment: atTop ? .top : .bottom) {
            if hides {
                Color.clear
                    .frame(height: Design.Size.edgeStrip)
                    .contentShape(.rect)
                    .onHover { inside in if inside { reveal.reachedEdge() } }
            }
            if reveal.isOut {
                let scheme = tint.resolved(in: outer)
                content()
                    // Its controls in the tint's scheme, read over any page, as the bar groups' (owner, 2026-11-13: contrast).
                    .environment(\.colorScheme, scheme)
                    .background(alignment: atTop ? .top : .bottom) {
                        // The bar's tint at the edge, fading into the page past the bar, over the fading blur.
                        GeometryReader { proxy in
                            ZStack {
                                BlurBackdropView(Design.Blur.group(size: proxy.size, margin: 0, top: atTop))
                                LinearGradient(
                                    gradient: .eased(
                                        from: BarTint.fill(for: scheme).opacity(Design.Fill.floatingBarShade),
                                        to: BarTint.fill(for: scheme).opacity(0)
                                    ),
                                    startPoint: atTop ? .top : .bottom,
                                    endPoint: atTop ? .bottom : .top
                                )
                            }
                        }
                        .padding(atTop ? .bottom : .top, -Design.Blur.groupFall)
                        .allowsHitTesting(false)
                    }
                    .onHover { over in
                        reveal.pointer(over: over)
                        if !over { settleSoon() }
                    }
                    .transition(BarGroupSlide.transition(atTop: atTop, inset: 0))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: atTop ? .top : .bottom)
        .animation(BarGroupSlide.animation, value: reveal.isOut)
        .onChange(of: hides) { _, now in reveal.hides = now }
        // Asked for or typed in: out, and it stays until the pointer has come over it and left.
        .onChange(of: typing, initial: true) { _, now in
            reveal.typing = now
            if now { reveal.reachedEdge() }
        }
    }

    private func settleSoon() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            reveal.settle()
        }
    }
}
