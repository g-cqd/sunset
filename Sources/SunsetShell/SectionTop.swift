import CoreGraphics
import SunsetMetrics

/// The measures of the top of a section's list (roadmap 0031): the title's row with what the section offers, then the search
/// field when there is something to search. The row is as tall as its buttons and the tabs' spacing under them, so that they
/// end above the field (the owner, 2026-11-15: they were over it).
package struct SectionTop {
    package let buttons: SidebarButtons
    /// The title is under the window buttons' row (the Library, which keeps the pin there); otherwise it is on that row.
    package let underLights: Bool
    /// The section has a search field.
    package let searchable: Bool

    package init(buttons: SidebarButtons, underLights: Bool, searchable: Bool) {
        self.buttons = buttons
        self.underLights = underLights
        self.searchable = searchable
    }

    private var layout: LayoutMetrics {
        buttons.layout
    }

    /// The room left above the title for the window buttons' row.
    package var lightsRow: Double {
        underLights ? buttons.header.height : 0
    }

    /// From the top of the title's row to its buttons: on the window buttons' row they start where the pin does.
    package var buttonTop: Double {
        underLights ? 0 : buttons.top
    }

    /// The title's row: on the window buttons' row it is that row; under it, its buttons and the tabs' spacing.
    package var titleRow: Double {
        let needed = buttonTop + buttons.metrics.size.height + layout.tabSpacing
        return underLights ? needed : max(buttons.header.height, needed)
    }

    /// The field and the tabs' spacing under it; nothing with no field.
    package var fieldRow: Double {
        searchable ? Design.Size.field + layout.tabSpacing : 0
    }

    /// The height of the whole top.
    package var height: Double {
        lightsRow + titleRow + fieldRow
    }

    /// Where the list starts: under the top and a breath, as the sidebar's rows start under its accessory.
    package var listTop: Double {
        height + Design.Space.xs
    }
}
