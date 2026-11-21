import Foundation
import SunsetPane

extension ProfilesModel {
    /// Another browser's containers as profiles (roadmap 0111 D; a Firefox container keeps its sites' data apart, as a
    /// profile does): one per name not taken yet, after the others; a name taken is that profile, not a second one.
    /// - Returns: the profiles made.
    @discardableResult
    package func adopt(named names: [String]) -> [ProfileModel] {
        var made: [ProfileModel] = []
        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !profiles.contains(where: { $0.profile.name.lowercased() == name.lowercased() }) else {
                continue
            }
            let profile = add()
            rename(profile, to: name)
            made.append(profile)
        }
        return made
    }
}
