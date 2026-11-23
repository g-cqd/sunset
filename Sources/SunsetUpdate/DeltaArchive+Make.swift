internal import CryptoKit
public import Foundation

extension DeltaArchive {
    private struct DraftPlan {
        let key: String
        let items: [Item]
        let payload: Data
    }

    private struct BlobChoice {
        let kind: BlobKind
        let bytes: Data
        let basePath: String?
        let baseSHA256: String?
    }

    /// Builds a single `SSDLTA2` archive for `target` covering each source in `sources` whose total payload does not
    /// exceed `maxSourceBytes`. Each file chooses copy (unchanged SHA-256), `BinaryDelta`, or LZMA full file, whichever
    /// is smallest.
    public static func make(
        target: URL,
        flavour: Flavour,
        toBuild: Int,
        sources: [SourceInput],
        maxSourceBytes: Int
    ) throws -> Built {
        let after = try BundleManifest.read(bundle: target)
        let afterFiles = after.entries.filter { $0.kind == .file }
        var targetCache: [String: (raw: Data, compressed: Data)] = [:]
        for entry in afterFiles {
            let raw = try Data(contentsOf: target.appending(path: entry.path))
            targetCache[entry.path] = (raw, try BoundedLZMA.compress(raw))
        }
        var drafts: [DraftPlan] = []
        for source in sources {
            let built = try buildSource(source, afterFiles: afterFiles, targetCache: targetCache)
            if built.payload.count <= maxSourceBytes {
                drafts.append(DraftPlan(key: source.key, items: built.items, payload: built.payload))
            }
        }
        return try assemble(flavour: flavour, toBuild: toBuild, manifest: after.entries, drafts: drafts)
    }

    /// Single-pass header/TOC assembly: `rangeOffset` in every `SourcePlan` is relative to the start of the payload
    /// region (`Header.size + tocLength`), so TOC compression never depends on its own compressed size!
    private static func assemble(
        flavour: Flavour,
        toBuild: Int,
        manifest: [BundleEntry],
        drafts: [DraftPlan]
    ) throws -> Built {
        var cursor = 0
        var sourceMap: [String: SourcePlan] = [:]
        var payloadRegion = Data()
        for draft in drafts {
            sourceMap[draft.key] = SourcePlan(
                rangeOffset: cursor,
                rangeLength: draft.payload.count,
                rangeSHA256: BundleManifest.hex(draft.payload),
                items: draft.items
            )
            payloadRegion.append(draft.payload)
            cursor += draft.payload.count
        }
        let toc = TOC(
            formatVersion: 2,
            flavour: flavour,
            toBuild: toBuild,
            targetManifest: manifest,
            sources: sourceMap
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let tocBytes = try BoundedLZMA.compress(try encoder.encode(toc))
        let tocDigest = SHA256.hash(data: tocBytes)
        let tocHex = tocDigest.map { String(format: "%02x", $0) }.joined()
        var archive = Header.magic
        archive.append(littleEndian: Int64(tocBytes.count))
        archive.append(contentsOf: tocDigest)
        archive.append(tocBytes)
        archive.append(payloadRegion)
        return Built(data: archive, toc: toc, tocSHA256: tocHex)
    }

    private static func buildSource(
        _ source: SourceInput,
        afterFiles: [BundleEntry],
        targetCache: [String: (raw: Data, compressed: Data)]
    ) throws -> (items: [Item], payload: Data) {
        let before = try BundleManifest.read(bundle: source.bundle)
        let byHash = before.filesByHash
        let oldByPath = Dictionary(
            uniqueKeysWithValues: before.entries.filter { $0.kind == .file }.map { ($0.path, $0) }
        )
        var payload = Data()
        var items: [Item] = []

        for entry in afterFiles {
            guard let hash = entry.sha256, let target = targetCache[entry.path] else { continue }
            if let same = byHash[hash] {
                items.append(
                    Item(
                        path: entry.path,
                        copyFrom: same.path,
                        kind: nil,
                        basePath: nil,
                        baseSHA256: hash,
                        offsetInRange: nil,
                        length: nil,
                        blobSHA256: nil,
                        expectedUncompressedSize: nil
                    )
                )
                continue
            }
            let blob = try bestBlob(
                for: entry.path,
                target: target,
                oldEntry: oldByPath[entry.path],
                oldBundle: source.bundle
            )
            let offset = payload.count
            payload.append(blob.bytes)
            items.append(
                Item(
                    path: entry.path,
                    copyFrom: nil,
                    kind: blob.kind,
                    basePath: blob.basePath,
                    baseSHA256: blob.baseSHA256,
                    offsetInRange: offset,
                    length: blob.bytes.count,
                    blobSHA256: BundleManifest.hex(blob.bytes),
                    expectedUncompressedSize: target.raw.count
                )
            )
        }
        return (items, payload)
    }

    private static func bestBlob(
        for path: String,
        target: (raw: Data, compressed: Data),
        oldEntry: BundleEntry?,
        oldBundle: URL
    ) throws -> BlobChoice {
        if let oldEntry, let oldHash = oldEntry.sha256 {
            let oldData = try Data(contentsOf: oldBundle.appending(path: path))
            let delta = try BinaryDelta.make(from: oldData, to: target.raw)
            if delta.count < target.compressed.count {
                return BlobChoice(kind: .delta, bytes: delta, basePath: path, baseSHA256: oldHash)
            }
        }
        return BlobChoice(kind: .full, bytes: target.compressed, basePath: nil, baseSHA256: nil)
    }
}
