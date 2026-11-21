public import Foundation

/// The profiles a Chromium browser lists in its `Local State` file (roadmap 0111 B).
public enum ChromiumProfiles {
    private struct File: Decodable {
        let profile: Profiles?
    }

    private struct Profiles: Decodable {
        private enum CodingKeys: String, CodingKey {
            case order = "profiles_order"
            case cache = "info_cache"
        }

        let order: [String]?
        let cache: [String: Info]?
    }

    private struct Info: Decodable {
        private enum CodingKeys: String, CodingKey {
            case name
            case isGuest = "is_guest"
        }

        let name: String?
        let isGuest: Bool?
    }

    /// Folders that are the browser's, not the person's.
    static let notThePersons: Set<String> = ["Guest Profile", "System Profile"]

    /// The profiles of `Local State`, in the order the browser shows them (by folder when it keeps none); throws when it
    /// is not Chromium's.
    public static func read(_ data: Data) throws -> [BrowserProfile] {
        let profiles = try JSONDecoder().decode(File.self, from: data).profile
        let cache = (profiles?.cache ?? [:]).filter { !notThePersons.contains($0.key) && $0.value.isGuest != true }
        let ordered = (profiles?.order ?? []).filter { cache[$0] != nil }
        let rest = cache.keys.filter { !ordered.contains($0) }.sorted()
        return (ordered + rest)
            .map { folder in
                let name = cache[folder]?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return BrowserProfile(folder: folder, name: name.isEmpty ? folder : name)
            }
    }
}
