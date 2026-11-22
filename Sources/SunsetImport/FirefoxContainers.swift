public import Foundation

/// The containers of a Firefox profile, from its `containers.json`.
public enum FirefoxContainers {
    private struct File: Decodable {
        let identities: [Identity]
    }

    private struct Identity: Decodable {
        let `public`: Bool?
        let name: String?
        let l10nId: String?
        let color: String?
        let icon: String?
    }

    /// The names Firefox shows for the containers it ships, which the file names by translation key only.
    static let shipped = [
        "user-context-personal": "Personal", "user-context-work": "Work", "user-context-banking": "Banking",
        "user-context-shopping": "Shopping"
    ]

    /// The person's containers (Firefox's own private ones left out), in the file's order; throws when it is not Firefox's.
    public static func read(_ data: Data) throws -> [BrowserContainer] {
        try JSONDecoder().decode(File.self, from: data).identities
            .compactMap { identity in
                guard identity.public != false else { return nil }
                let name = identity.name ?? identity.l10nId.flatMap { shipped[$0] } ?? ""
                guard !name.isEmpty else { return nil }
                return BrowserContainer(
                    name: name,
                    color: identity.color.flatMap { $0.isEmpty ? nil : $0 },
                    icon: identity.icon.flatMap { $0.isEmpty ? nil : $0 }
                )
            }
    }
}
