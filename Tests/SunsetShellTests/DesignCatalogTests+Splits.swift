import SwiftUI

@testable import SunsetShell

extension DesignCatalogTests {
    var splitAlignment: CatalogSheet {
        func sub(_ title: String, _ symbol: String, iconOnly: Bool, focused: Bool) -> some View {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 12)).frame(width: 16, height: 16)
                if !iconOnly { Text(title).font(.system(size: 12)).lineLimit(1) }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: iconOnly ? .center : .leading)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(focused ? 0.14 : 0.05))
            )
        }
        func split(iconOnly: Bool, panes: Int) -> AnyView {
            let items = [("zsh", "terminal"), ("example.com", "globe"), ("vim", "terminal")].prefix(panes)
            return AnyView(
                HStack(spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        sub(item.0, item.1, iconOnly: iconOnly, focused: index == 0)
                    }
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(0.14)))
                .padding(4).background(Color(white: 0.09))
            )
        }
        return CatalogSheet(
            title: "Split tabs: alignment",
            note:
                "A sub-row with an icon and its title starts at its leading edge; one that only has room for its icon centres it.",
            columns: [
                .init(
                    title: "Icon and title: leading",
                    examples: [
                        .init(label: "two panes", view: split(iconOnly: false, panes: 2)),
                        .init(label: "three panes", view: split(iconOnly: false, panes: 3))
                    ]
                ),
                .init(
                    title: "Icon only: centred",
                    examples: [
                        .init(label: "three panes", view: split(iconOnly: true, panes: 3))
                    ]
                )
            ],
            width: 221
        )
    }
}
