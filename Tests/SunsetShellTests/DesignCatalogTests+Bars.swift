import SunsetMetrics
import SwiftUI

@testable import SunsetShell

/// Mock-ups of the shared Field and of the bars' buttons (design 0003 step 3): the parts are drawn as the proposal would draw them; the
/// address field's real lock and zoom label live in SunsetWeb and are shown in the app's shots.
extension DesignCatalogTests {
    private func field(gap: Double, zoom: Bool = false, privateMark: Bool = false, text: String = "example.com")
        -> some View
    {
        HStack(spacing: gap) {
            if privateMark {
                Text("Private").font(.caption.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.18)))
            } else {
                Image(systemName: "lock").font(.caption).foregroundStyle(.secondary)
            }
            Text(text).lineLimit(1)
            Spacer(minLength: 0)
            if zoom { Text("115%").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
        }
        .padding(.horizontal, Design.Space.m)
        .frame(height: Design.Size.field)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(privateMark ? Color.black.opacity(0.7) : Color.primary.opacity(0.08))
        )
    }

    private func on(_ background: Color, scheme: ColorScheme = .dark, _ view: some View) -> AnyView {
        AnyView(view.padding(8).background(background).environment(\.colorScheme, scheme))
    }

    var fields: CatalogSheet {
        CatalogSheet(
            title: "The shared Field (mock-up)",
            note:
                "Measured in the app: field edge to the lock's ink 10 pt, lock to text 7.5 pt. Proposed (the row rule, more space): both 10, "
                + "so the gap after the lock grows by 2.5. One look in four places; its edge (a fill of primary at 8 %) checked on the "
                + "backgrounds it sits on: the sidebar, the window, a light page under a bar, a private page.",
            columns: [
                .init(
                    title: "Today (gap 4)",
                    examples: [
                        .init(label: "sidebar", view: on(Color(white: 0.13), field(gap: 4))),
                        .init(label: "with zoom", view: on(Color(white: 0.13), field(gap: 4, zoom: true))),
                        .init(
                            label: "private",
                            view: on(Color(white: 0.13), field(gap: 4, privateMark: true, text: "Address"))
                        ),
                        .init(label: "window", view: on(Color(white: 0.09), field(gap: 4))),
                        .init(label: "light page", view: on(.white, scheme: .light, field(gap: 4)))
                    ]
                ),
                .init(
                    title: "Proposed (gap 6.5: ink 10 / 10)",
                    examples: [
                        .init(label: "sidebar", view: on(Color(white: 0.13), field(gap: 6.5))),
                        .init(label: "with zoom", view: on(Color(white: 0.13), field(gap: 6.5, zoom: true))),
                        .init(
                            label: "private",
                            view: on(Color(white: 0.13), field(gap: 6.5, privateMark: true, text: "Address"))
                        ),
                        .init(label: "window", view: on(Color(white: 0.09), field(gap: 6.5))),
                        .init(label: "light page", view: on(.white, scheme: .light, field(gap: 6.5)))
                    ]
                )
            ],
            width: 260
        )
    }

    /// A bar of the window holding three buttons and a field, with the buttons drawn one way.
    private func bar(_ style: Int, pressed: Bool = false, disabled: Bool = false) -> AnyView {
        func button(_ symbol: String, _ index: Int) -> AnyView {
            let off = disabled && index == 1
            switch style {
                case 0:
                    return AnyView(
                        Image(systemName: symbol).frame(width: 24, height: 24)
                            .foregroundStyle(off ? .tertiary : .primary)
                    )
                case 1:
                    return AnyView(
                        SidebarIconButtonFace(
                            label: SidebarSymbol(name: symbol, filled: false),
                            pressed: pressed && index == 0,
                            metrics: SidebarButtonMetrics(size: CGSize(width: 24, height: 24), radius: 6)
                        )
                        .opacity(off ? 0.4 : 1)
                    )
                default:
                    return AnyView(
                        Button {
                        } label: {
                            Image(systemName: symbol).frame(width: 16, height: 16)
                        }
                        .buttonStyle(.bordered).controlSize(.small).disabled(off)
                    )
            }
        }
        return AnyView(
            HStack(spacing: Design.Space.xs) {
                button("chevron.left", 0)
                button("chevron.right", 1)
                button("arrow.clockwise", 2)
                field(gap: 6.5)
            }
            .padding(.horizontal, Design.Space.s)
            .frame(width: 330, height: Design.Size.bar)
            // Glass does not draw off-screen (ImageRenderer): a grey stands in for the bar's surface.
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(white: 0.22)))
            .padding(10)
            .environment(\.colorScheme, .dark)
        )
    }

    var barButtons: CatalogSheet {
        CatalogSheet(
            title: "The bars' buttons (mock-up)",
            note:
                "Back, forward (disabled here) and reload in a 38 pt bar. A: today, system borderless (no fill on hover). B: the sidebar's "
                + "IconButton, 24 square, radius 6 so it nests in the bar's 12 at its 6 inset, the same hover and pressed fills as the pin "
                + "and the +. C: system bordered buttons, standing in for the glass button style (glass does not draw off-screen; glass buttons on a glass bar are two layers of glass, which the HIG advises against). The bar's glass is drawn grey here. The find bar's arrows "
                + "would follow the same choice.",
            columns: [
                .init(
                    title: "Variants",
                    examples: [
                        .init(label: "A system borderless", view: bar(0, disabled: true)),
                        .init(label: "B IconButton, rest", view: bar(1, disabled: true)),
                        .init(label: "B IconButton, pressed", view: bar(1, pressed: true, disabled: true)),
                        .init(label: "C bordered (≈ glass)", view: bar(2, disabled: true))
                    ]
                )
            ],
            width: 360
        )
    }
}
