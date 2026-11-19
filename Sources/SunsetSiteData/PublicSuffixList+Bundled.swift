import Foundation

extension PublicSuffixList {
    /// The list Sunset ships (`Resources/public_suffix_list.dat`), read once (about 10,000 rules) and kept.
    public static func bundled() throws -> PublicSuffixList {
        guard let list = shared else { throw CocoaError(.fileNoSuchFile) }
        return list
    }

    private static let shared: PublicSuffixList? = {
        guard let url = Bundle.module.url(forResource: "Resources/public_suffix_list", withExtension: "dat"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return PublicSuffixList(text: text)
    }()
}
