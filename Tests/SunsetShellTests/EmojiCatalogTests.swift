import Foundation
import Testing

@testable import SunsetShell

/// The emoji a person can pick as an icon (the owner, 2026-11-17: the picker "should allow for emojis as well as symbols"),
/// read from the system's own names (`CoreEmoji`). The system gives their names, not their order: faces come first, flags
/// last, the rest by where Unicode has them.
@Suite("The emoji catalog")
struct EmojiCatalogTests {
    private func resources() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "emoji-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: folder.appending(path: "en.lproj"),
            withIntermediateDirectories: true
        )
        let names = [
            "\u{1F680}": "rocket", "\u{1F600}": "grinning face", "\u{1F1EB}\u{1F1F7}": "flag of France",
            "\u{1F469}\u{200D}\u{1F527}": "woman mechanic", "\u{2764}\u{FE0F}": "red heart",
            "\u{1F9D1}": "person", "\u{1F525}": "fire", "": "nothing", "\u{1F602}": "face with tears of joy"
        ]
        try PropertyListSerialization.data(fromPropertyList: names, format: .binary, options: 0)
            .write(to: folder.appending(path: "en.lproj/AppleName.strings"))
        return folder
    }

    @Test func `faces first, then the rest by where Unicode has them, flags last; nothing empty`() throws {
        let catalog = EmojiCatalog.load(from: try resources())
        #expect(
            catalog.emoji.map(\.text) == [
                "\u{1F600}", "\u{1F602}", "\u{1F9D1}", "\u{1F469}\u{200D}\u{1F527}", "\u{1F525}", "\u{1F680}",
                "\u{2764}\u{FE0F}", "\u{1F1EB}\u{1F1F7}"
            ]
        )
        #expect(catalog.emoji.first?.name == "grinning face")
    }

    @Test func `found by the words of its name: every word typed begins one; a word that is whole comes first`() throws
    {
        let catalog = EmojiCatalog.load(from: try resources())
        #expect(catalog.search("rock").map(\.text) == ["\u{1F680}"])
        #expect(catalog.search("face").map(\.name) == ["grinning face", "face with tears of joy"])
        #expect(catalog.search("fa tea").map(\.name) == ["face with tears of joy"])
        #expect(catalog.search("FLAG fr").map(\.text) == ["\u{1F1EB}\u{1F1F7}"])
        #expect(catalog.search("zzz").isEmpty && catalog.search("").count == 8)
    }

    @Test func `missing files give no emoji, not a failure; the system's own are readable on this machine`() {
        #expect(EmojiCatalog.load(from: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)")).emoji.isEmpty)
        let system = EmojiCatalog.load()
        #expect(system.emoji.count > 1000, "\(system.emoji.count)")
        #expect(system.search("rocket").first?.text == "\u{1F680}")
        #expect(system.emoji.first.map { $0.text.unicodeScalars.first?.value ?? 0 } ?? 0 >= 0x1F600)
    }
}
