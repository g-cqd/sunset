import SunsetMetrics
package import SwiftUI

/// The top of a section's list, drawn (`SectionTop` has its measures): the title with what the section offers at its end, then
/// the search field when the section has one.
package struct SectionHeading<Actions: View, Field: View>: View {
    let top: SectionTop
    let title: String
    let actions: Actions
    let field: Field

    package init(
        top: SectionTop,
        title: String,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder field: () -> Field
    ) {
        self.top = top
        self.title = title
        self.actions = actions()
        self.field = field()
    }

    private var layout: LayoutMetrics {
        top.buttons.layout
    }

    package var body: some View {
        VStack(spacing: 0) {
            if top.lightsRow > 0 { Color.clear.frame(height: top.lightsRow) }
            // The title is centred on its buttons, which are at the row's top; the tabs' spacing is under them.
            HStack(spacing: Design.Space.xs) {
                Text(title).font(Design.Text.body.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 0)
                actions
            }
            .environment(\.sidebarButtonMetrics, top.buttons.metrics)
            .frame(height: top.buttons.metrics.size.height)
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.top, top.buttonTop)
            .frame(height: top.titleRow, alignment: .top)
            if top.searchable { field.padding(.bottom, layout.tabSpacing) }
        }
        .padding(.horizontal, layout.tabSideInset)
    }
}
