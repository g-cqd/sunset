import Foundation

/// The XML of a KeePass database written from the vault (`KeePassWriter`): one group a folder (a folder "A / B" nested),
/// each entry its title, username, password, address, one-time code (as KeePassXC's `otp`), notes, tags and its other
/// fields as strings of their names; secret fields protected (hidden by the inner stream, in document order); attachments
/// referenced by their place in the inner header.
enum KeePassXMLWriter {
    /// The strings KeePass names itself, from the vault's login fields.
    private static let standard = [
        "Username": "UserName", "Password": "Password", "Website": "URL", "One-Time Code": "otp"
    ]

    static func xml(
        _ entries: [VaultEntry],
        now: Date,
        attachments: inout [Data],
        protect: (inout [UInt8]) -> Void
    ) -> String {
        let time = Self.time(now)
        let tree = Folder(entries)
        var out = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<KeePassFile><Meta>"
        out += "<Generator>Sunset</Generator><DatabaseName>Sunset</DatabaseName>"
        out += "<MemoryProtection><ProtectPassword>True</ProtectPassword></MemoryProtection></Meta><Root>"
        write(tree, name: "Sunset", time: time, into: &out, attachments: &attachments, protect: protect)
        out += "</Root></KeePassFile>"
        return out
    }

    /// The entries by folder, folders inside folders.
    private final class Folder {
        var entries: [VaultEntry] = []
        var folders: [(name: String, folder: Folder)] = []

        init() {}

        convenience init(_ entries: [VaultEntry]) {
            self.init()
            for entry in entries {
                let path = (entry.folder ?? "").components(separatedBy: " / ").filter { !$0.isEmpty }
                var folder = self
                for name in path {
                    if let found = folder.folders.first(where: { $0.name == name }) {
                        folder = found.folder
                    } else {
                        let made = Folder()
                        folder.folders.append((name, made))
                        folder = made
                    }
                }
                folder.entries.append(entry)
            }
        }
    }

    private static func write(
        _ folder: Folder,
        name: String,
        time: String,
        into out: inout String,
        attachments: inout [Data],
        protect: (inout [UInt8]) -> Void
    ) {
        out += "<Group><UUID>\(uuid(UUID()))</UUID><Name>\(escaped(name))</Name>\(times(time))"
        for entry in folder.entries {
            writeEntry(entry, time: time, into: &out, attachments: &attachments, protect: protect)
        }
        for sub in folder.folders {
            write(sub.folder, name: sub.name, time: time, into: &out, attachments: &attachments, protect: protect)
        }
        out += "</Group>"
    }

    private static func writeEntry(
        _ entry: VaultEntry,
        time: String,
        into out: inout String,
        attachments: inout [Data],
        protect: (inout [UInt8]) -> Void
    ) {
        out += "<Entry><UUID>\(uuid(entry.id))</UUID>"
        if !entry.tags.isEmpty { out += "<Tags>\(escaped(entry.tags.joined(separator: ";")))</Tags>" }
        out += times(time)
        var used: Set<String> = ["Title", "Notes"]
        var strings: [(key: String, value: String, secret: Bool)] = [("Title", entry.title, false)]
        let isLogin = entry.template == EntryTemplate.login.id
        for field in entry.sections.flatMap(\.fields) where !field.value.isEmpty {
            var key = isLogin ? standard[field.name] ?? field.name : field.name
            if key.isEmpty { key = "Field" }
            var number = 2
            let base = key
            while used.contains(key) {
                key = "\(base) (\(number))"
                number += 1
            }
            used.insert(key)
            strings.append((key, field.value, field.isSecret || key == "Password"))
        }
        strings.append(("Notes", entry.note, false))
        for string in strings {
            out += "<String><Key>\(escaped(string.key))</Key>"
            if string.secret {
                var bytes = [UInt8](string.value.utf8)
                protect(&bytes)
                out += "<Value Protected=\"True\">\(Data(bytes).base64EncodedString())</Value></String>"
            } else {
                out += "<Value>\(escaped(string.value))</Value></String>"
            }
        }
        for attachment in entry.attachments ?? [] {
            out += "<Binary><Key>\(escaped(attachment.filename))</Key><Value Ref=\"\(attachments.count)\"/></Binary>"
            attachments.append(attachment.data)
        }
        out += "</Entry>"
    }

    private static func times(_ time: String) -> String {
        "<Times><CreationTime>\(time)</CreationTime><LastModificationTime>\(time)</LastModificationTime>"
            + "<LastAccessTime>\(time)</LastAccessTime><Expires>False</Expires></Times>"
    }

    /// A KDBX 4 time: Base64 of seconds since 0001-01-01, 64-bit little-endian.
    private static func time(_ date: Date) -> String {
        let seconds = Int64(date.timeIntervalSince1970) + 62_135_596_800
        return Data(KeePassWriter.le64(UInt64(bitPattern: seconds))).base64EncodedString()
    }

    private static func uuid(_ id: UUID) -> String {
        withUnsafeBytes(of: id.uuid) { Data($0) }.base64EncodedString()
    }

    /// Text as XML takes it: its five special characters as entities, the control characters XML 1.0 refuses left out.
    private static func escaped(_ text: String) -> String {
        String(
            String.UnicodeScalarView(
                text.unicodeScalars.flatMap { scalar -> [Unicode.Scalar] in
                    if let entity = entities[scalar] { return Array(entity.unicodeScalars) }
                    let allowed = scalar.value >= 0x20 || scalar == "\t" || scalar == "\n" || scalar == "\r"
                    return allowed ? [scalar] : []
                }
            )
        )
    }

    private static let entities: [Unicode.Scalar: String] = [
        "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&apos;"
    ]
}
