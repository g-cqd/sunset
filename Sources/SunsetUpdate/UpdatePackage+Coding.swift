public import Foundation

extension UpdatePackage {
    /// The package that turns the bundle at `old` (build `from`) into the one at `new` (build `to`).
    public static func make(old: URL, new: URL, from: Int, to: Int) throws -> Data {
        let before = try BundleManifest.read(bundle: old)
        let after = try BundleManifest.read(bundle: new)
        let byHash = before.filesByHash
        let oldFiles = Set(before.entries.filter { $0.kind == .file }.map(\.path))
        var deltas = Data()
        var items: [Item] = []
        for entry in after.entries {
            guard entry.kind == .file, let hash = entry.sha256 else {
                items.append(Item(entry: entry, copy: nil, base: nil, offset: nil, length: nil))
                continue
            }
            if let same = byHash[hash] {
                items.append(Item(entry: entry, copy: same.path, base: nil, offset: nil, length: nil))
                continue
            }
            let base = oldFiles.contains(entry.path) ? entry.path : nil
            let baseData = try base.map { try Data(contentsOf: old.appending(path: $0)) } ?? Data()
            let delta = try BinaryDelta.make(from: baseData, to: try Data(contentsOf: new.appending(path: entry.path)))
            items.append(Item(entry: entry, copy: nil, base: base, offset: deltas.count, length: delta.count))
            deltas.append(delta)
        }
        let header = try JSONEncoder().encode(Header(from: from, to: to, items: items))
        var package = magic
        package.append(littleEndian: Int64(header.count))
        package.append(header)
        package.append(deltas)
        return package
    }

    /// The package in `data`; every path and every delta's place checked.
    public init(decoding data: Data) throws(Failure) {
        let bytes = [UInt8](data.prefix(Self.magic.count + 8))
        guard bytes.count >= Self.magic.count, bytes.prefix(Self.magic.count).elementsEqual(Self.magic) else {
            throw .notAPackage
        }
        guard let length = try? BinaryDelta.number(in: bytes, at: Self.magic.count), length >= 0,
            length <= data.count - Self.magic.count - 8
        else { throw .malformed }
        let start = data.startIndex + Self.magic.count + 8
        guard let header = try? JSONDecoder().decode(Header.self, from: data[start ..< start + length]) else {
            throw .malformed
        }
        let deltas = data[(start + length)...]
        // Nothing is written under a link the package makes: that would write where the link points, outside.
        let links = header.items.filter { $0.entry.kind == .link }.map { $0.entry.path + "/" }
        for item in header.items where links.contains(where: item.entry.path.hasPrefix) {
            throw .outside(item.entry.path)
        }
        for item in header.items {
            for path in [item.entry.path, item.copy, item.base].compactMap(\.self) {
                guard BundleEntry.link(path, target: "").staysInside else { throw .outside(path) }
            }
            if let offset = item.offset {
                guard let length = item.length, offset >= 0, length >= 0, length <= deltas.count - offset else {
                    throw .malformed
                }
            }
        }
        self.init(from: header.from, to: header.to, items: header.items, deltas: Data(deltas))
    }
}
