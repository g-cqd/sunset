/// An alert or a confirmation in Sunset's own look (the owner's note n73): what it says and its buttons; `SunsetAlertView`
/// draws it, `SunsetAlerts` shows it.
package struct SunsetAlert: Sendable {
    package struct Button: Sendable, Equatable {
        package enum Role: Sendable, Equatable {
            case plain
            case cancel
            case destructive
        }

        package let title: String
        package let role: Role

        package static func plain(_ title: String) -> Self {
            Self(title: title, role: .plain)
        }

        package static func cancel(_ title: String) -> Self {
            Self(title: title, role: .cancel)
        }

        package static func destructive(_ title: String) -> Self {
            Self(title: title, role: .destructive)
        }
    }

    package var title: String
    package var message: String
    /// Text shown as it is, in a fixed-width font (what a paste would send).
    package var preview: String?
    /// An image of what it is about (an extension's icon), as PNG data.
    package var icon: [UInt8]?
    package var buttons: [Button]
    /// The button Return presses, by index; a Cancel button there means Return presses Cancel (a risky action is clicked).
    package var defaultButton: Int

    package init(
        title: String,
        message: String,
        preview: String? = nil,
        icon: [UInt8]? = nil,
        buttons: [Button],
        defaultButton: Int
    ) {
        self.title = title
        self.message = message
        self.preview = preview
        self.icon = icon
        self.buttons = buttons
        self.defaultButton = defaultButton
    }

    /// The button Escape presses: the Cancel one, else the only one.
    package var escapeButton: Int? {
        buttons.firstIndex { $0.role == .cancel } ?? (buttons.count == 1 ? 0 : nil)
    }

    package var returnButton: Int {
        defaultButton
    }

    /// The order the buttons show in, leading to trailing, as macOS's alerts: a destructive one first, then the others,
    /// Cancel, the default last.
    package var shownOrder: [Int] {
        let indices = Array(buttons.indices)
        let destructive = indices.filter { buttons[$0].role == .destructive && $0 != defaultButton }
        let cancel = indices.filter { buttons[$0].role == .cancel && $0 != defaultButton }
        let others = indices.filter { !destructive.contains($0) && !cancel.contains($0) && $0 != defaultButton }
        return destructive + others + cancel + [defaultButton]
    }
}
