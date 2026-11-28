import Foundation

/// The entries of a KeePass database's XML, as they are: their strings (protected ones revealed with the inner stream, in
/// the order the document has them, history and all), their attachments' names and references, tags, groups, and the
/// previous values of their password. Entries in the recycle bin are marked.
final class KeePassXML: NSObject, XMLParserDelegate {
    struct Entry {
        var strings: [(key: String, value: String, protected: Bool)] = []
        var binaries: [(name: String, reference: Int)] = []
        var tags: [String] = []
        var groups: [String] = []
        var deleted = false
        /// The password each earlier version had, and when that version was last changed.
        var history: [(password: String, changed: Date?)] = []
        var changed: Date?

        func string(_ key: String) -> String {
            strings.first { $0.key == key }?.value ?? ""
        }
    }

    private(set) var entries: [Entry] = []
    private var stream: ChaCha20
    private var path: [String] = []
    /// Each open group: its name and id.
    private var groups: [(name: String, id: String)] = []
    private var recycleBin: String?
    private var entry: Entry?
    /// The earlier versions of the entry being read, in its History.
    private var older: Entry?
    private var key = ""
    private var text = ""
    private var protected = false
    private var reference: Int?
    private var failed = false

    private init(stream: ChaCha20) {
        self.stream = stream
    }

    /// The entries of `contents`; nil when its XML is not a KeePass file's.
    static func entries(of contents: KeePassFile.Contents) -> [Entry]? {
        let reader = KeePassXML(stream: contents.protected)
        let parser = XMLParser(data: contents.xml)
        parser.shouldResolveExternalEntities = false
        parser.delegate = reader
        guard parser.parse(), !reader.failed else { return nil }
        return reader.entries
    }

    func parser(
        _ parser: XMLParser,
        didStartElement name: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        path.append(name)
        text = ""
        switch name {
            case "Group": groups.append(("", ""))
            case "Entry" where path.contains("History"): older = Entry()
            case "Entry": entry = Entry()
            case "Value":
                protected = attributes["Protected"]?.lowercased() == "true"
                reference = attributes["Ref"].flatMap(Int.init)
            default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        defer { path.removeLast() }
        let parent = path.dropLast().last
        switch (name, parent) {
            case ("RecycleBinUUID", "Meta"): recycleBin = text
            case ("Name", "Group"):
                if var last = groups.popLast() {
                    last.name = text
                    groups.append(last)
                }
            case ("UUID", "Group"):
                if var last = groups.popLast() {
                    last.id = text
                    groups.append(last)
                }
            case ("Group", _): groups.removeLast()
            case ("Key", "String"), ("Key", "Binary"): key = text
            case ("Value", "String"): addString()
            case ("Value", "Binary"):
                if let reference { mutate { $0.binaries.append((key, reference)) } }
            case ("Tags", "Entry"):
                mutate {
                    $0.tags = text.split { $0 == ";" || $0 == "," }.map { $0.trimmingCharacters(in: .whitespaces) }
                }
            case ("LastModificationTime", "Times"): mutate { $0.changed = Self.date(text) }
            case ("Entry", _) where path.contains("History") && older != nil:
                if let older { entry?.history.append((older.string("Password"), older.changed)) }
                older = nil
            case ("Entry", _): finishEntry()
            default: break
        }
        text = ""
    }

    /// A string of the entry, revealed when protected: the inner stream moves on for every protected value, in order.
    private func addString() {
        var value = text
        if protected {
            guard let hidden = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                failed = true
                return
            }
            value = String(decoding: stream.apply([UInt8](hidden)), as: UTF8.self)
        }
        let isProtected = protected
        mutate { $0.strings.append((key, value, isProtected)) }
    }

    private func finishEntry() {
        guard var done = entry else { return }
        // The root group is the database itself: its name is no folder.
        done.groups = groups.dropFirst().map(\.name)
        done.deleted = recycleBin.map { bin in !bin.isEmpty && groups.contains { $0.id == bin } } ?? false
        entries.append(done)
        entry = nil
    }

    /// The entry being read: an earlier version in its history, else the entry.
    private func mutate(_ change: (inout Entry) -> Void) {
        if var version = older {
            change(&version)
            older = version
        } else if var current = entry {
            change(&current)
            entry = current
        }
    }

    /// A KDBX 4 time: Base64 of seconds since 0001-01-01 (64-bit, little-endian); else ISO 8601, as KDBX 3 wrote it.
    static func date(_ text: String) -> Date? {
        if let bytes = Data(base64Encoded: text), bytes.count == 8 {
            let seconds = bytes.reversed().reduce(Int64(0)) { $0 << 8 | Int64($1) }
            return Date(timeIntervalSince1970: TimeInterval(seconds - 62_135_596_800))
        }
        return ISO8601DateFormatter().date(from: text)
    }
}
