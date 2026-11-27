import AppIntents

/// A command of Sunset's menus, as Shortcuts and Spotlight offer it.
struct SunsetCommand: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sunset Command")
    static let defaultQuery = SunsetCommandQuery()

    let id: String
    let title: String
    let symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol))
    }
}
