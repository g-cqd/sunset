/// The brands a Chromium browser names in `navigator.userAgentData` (roadmap 0045 F): Chromium, the browser, and a
/// made-up brand, ordered and spelt by the major version, as Chromium's `GenerateBrandVersionList` does
/// (components/embedder_support/user_agent_utils.cc, read 2026-11-18). Chrome 160 gave the same on this Mac.
package enum ChromiumBrands {
    package struct Brand: Equatable {
        package let brand: String
        package let version: String
    }

    package static func list(major: Int, brand: String) -> [Brand] {
        let characters = [" ", "(", ":", "-", ".", "/", ")", ";", "=", "?", "_"]
        let greased = Brand(
            brand: "Not" + characters[major % characters.count] + "A" + characters[(major + 1) % characters.count]
                + "Brand",
            version: ["8", "99", "24"][major % 3]
        )
        let given = [
            greased, Brand(brand: "Chromium", version: String(major)), Brand(brand: brand, version: String(major))
        ]
        let orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
        let order = orders[major % orders.count]
        var shuffled = given
        for (index, place) in order.enumerated() { shuffled[place] = given[index] }
        return shuffled
    }
}
