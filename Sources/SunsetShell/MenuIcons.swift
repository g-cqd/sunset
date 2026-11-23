import Foundation

/// Which menu items show their symbol. The owner chooses (n139); until then a launch variable shows each choice for the
/// screenshots (`SUNSET_PROBE_MENU_ICONS`: none, actions, all).
enum MenuIcons {
    case none
    case actions
    case all

    static let style: Self =
        switch ProcessInfo.processInfo.environment["SUNSET_PROBE_MENU_ICONS"] {
            case "actions": .actions
            case "all": .all
            default: .none
        }

    func shows(_ kind: MenuItemLabel.Kind) -> Bool {
        switch self {
            case .none: false
            case .actions: kind == .action
            case .all: true
        }
    }
}
