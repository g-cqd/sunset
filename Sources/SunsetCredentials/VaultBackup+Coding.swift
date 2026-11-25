import Foundation
import SunsetStorage

extension VaultBackup {
    static func parse(_ data: Data) throws(Failure) -> Parsed {
        guard data.count >= magic.count + 1 + 4, data.prefix(magic.count) == magic else { throw .notABackup }
        let version = data[data.startIndex + magic.count]
        guard version == currentVersion else { throw .unsupportedVersion(version) }

        var cursor = data.startIndex + magic.count + 1
        let headerLength = try readUInt32(data, cursor: &cursor)
        guard headerLength <= maxHeaderBytes, cursor + headerLength <= data.endIndex else { throw .damaged }
        let headerSlice = data[cursor ..< cursor + headerLength]
        cursor += headerLength

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let rawHeader = try? decoder.decode(RawHeader.self, from: headerSlice) else { throw .damaged }
        guard rawHeader.recordCount >= 0, rawHeader.recordCount <= maxRecordCount else { throw .damaged }
        // Refuse backups carrying device-bound Touch ID wraps.
        guard !rawHeader.factorSlots.contains(where: { $0.factor == .touchID }) else { throw .damaged }

        var records: [(id: UUID, sealed: Data)] = []
        records.reserveCapacity(min(rawHeader.recordCount, 1024))
        var seen = Set<UUID>()
        for _ in 0 ..< rawHeader.recordCount {
            let id = try readUUID(data, cursor: &cursor)
            guard seen.insert(id).inserted else { throw .damaged }
            let sealedLength = try readUInt32(data, cursor: &cursor)
            guard sealedLength <= maxRecordBytes, cursor + sealedLength <= data.endIndex else { throw .damaged }
            let sealed = Data(data[cursor ..< cursor + sealedLength])
            cursor += sealedLength
            records.append((id, sealed))
        }
        // Trailing bytes are rejected so truncation/concatenation tampering cannot pass silently.
        guard cursor == data.endIndex else { throw .damaged }
        return Parsed(version: version, rawHeader: rawHeader, records: records)
    }

    static func decrypt(_ parsed: Parsed, with key: StorageKey) throws(Failure) -> Contents {
        let seal = Seal(key: key, purpose: .vaultRecord)
        let vaultID = parsed.rawHeader.vaultID
        var entries: [VaultEntry] = []
        var templates: [EntryTemplate] = []
        var neverSave = Set<String>()
        let decoder = JSONDecoder()

        for (id, sealed) in parsed.records {
            let identity = "vault:\(vaultID.uuidString)/record:\(id.uuidString)"
            guard let plain = try? seal.open(sealed, identity: identity),
                let record = try? decoder.decode(VaultRecord.self, from: plain)
            else { throw .damaged }
            switch record {
                case .entry(let entry): entries.append(entry)
                case .template(let template): templates.append(template)
                case .neverSave(let sites): neverSave.formUnion(sites)
            }
        }
        let header = Header(
            version: parsed.version,
            vaultID: vaultID,
            createdAt: parsed.rawHeader.createdAt,
            factors: parsed.rawHeader.factorSlots.map(\.factor),
            recordCount: parsed.rawHeader.recordCount
        )
        return Contents(header: header, entries: entries, templates: templates, neverSave: neverSave)
    }

    static func appendUInt32(_ value: UInt32, to data: inout Data) {
        var big = value.bigEndian
        withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
    }

    static func appendUUID(_ id: UUID, to data: inout Data) {
        withUnsafeBytes(of: id.uuid) { data.append(contentsOf: $0) }
    }

    private static func readUInt32(_ data: Data, cursor: inout Data.Index) throws(Failure) -> Int {
        guard cursor + 4 <= data.endIndex else { throw .damaged }
        let b0 = UInt32(data[cursor])
        let b1 = UInt32(data[cursor + 1])
        let b2 = UInt32(data[cursor + 2])
        let b3 = UInt32(data[cursor + 3])
        cursor += 4
        return Int((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
    }

    private static func readUUID(_ data: Data, cursor: inout Data.Index) throws(Failure) -> UUID {
        guard cursor + 16 <= data.endIndex else { throw .damaged }
        var bytes: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        _ = withUnsafeMutableBytes(of: &bytes) { dst in
            data.copyBytes(to: dst, from: cursor ..< cursor + 16)
        }
        cursor += 16
        return UUID(uuid: bytes)
    }
}
