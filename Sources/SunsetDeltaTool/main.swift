import Foundation
import SunsetUpdate

// Sunset's deltas, SSDLTA2 archives, verification, and release index tooling (ADR-0122, ADR-0125):
//
//   SunsetDeltaTool make OLD NEW DELTA
//   SunsetDeltaTool apply OLD DELTA NEW
//   SunsetDeltaTool package OLD.app NEW.app FROM TO OUT
//   SunsetDeltaTool stage PACKAGE RUNNING.app STAGING.app
//   SunsetDeltaTool verify A.app B.app
//   SunsetDeltaTool archive FLAVOUR TO_BUILD MAX_BYTES TARGET.app OUT.deltas [KEY:SRC.app ...]
//   SunsetDeltaTool index TAG BUILD NOTES_FILE OUT.json [FLAVOUR:ARCH:ZIP:DELTAS ...]

let words = Array(CommandLine.arguments.dropFirst())
let usage = """
    usage:
      SunsetDeltaTool make OLD NEW DELTA
      SunsetDeltaTool apply OLD DELTA NEW
      SunsetDeltaTool package OLD NEW FROM TO OUT
      SunsetDeltaTool stage PACKAGE APP STAGING
      SunsetDeltaTool verify A.app B.app
      SunsetDeltaTool archive native|webkit TO_BUILD MAX_BYTES TARGET.app OUT.deltas [KEY:SRC.app ...]
      SunsetDeltaTool index TAG BUILD NOTES_FILE OUT.json [native|webkit:ARCH:ZIP:DELTAS ...]
    """

func parseFlavour(_ raw: String) -> Flavour? {
    switch raw.lowercased() {
        case "native", "sunset": .native
        case "webkit", "sunset-webkit": .webKit
        default: nil
    }
}

func makeArchive(_ words: [String]) throws -> String? {
    guard words.count >= 6,
        let flavour = parseFlavour(words[1]),
        let toBuild = Int(words[2]),
        let maxBytes = Int(words[3])
    else { return nil }
    let target = URL(filePath: words[4])
    let output = URL(filePath: words[5])
    var sources: [DeltaArchive.SourceInput] = []
    for spec in words.dropFirst(6) {
        guard let colon = spec.firstIndex(of: ":") else { return nil }
        let key = String(spec[..<colon])
        let path = String(spec[spec.index(after: colon)...])
        sources.append(DeltaArchive.SourceInput(key: key, bundle: URL(filePath: path)))
    }
    let built = try DeltaArchive.make(
        target: target,
        flavour: flavour,
        toBuild: toBuild,
        sources: sources,
        maxSourceBytes: maxBytes
    )
    try built.data.write(to: output)
    // Self-verify every included source plan by staging into a temp directory and comparing BundleManifests.
    for source in sources {
        guard let plan = built.toc.sources[source.key] else { continue }
        let staging = FileManager.default.temporaryDirectory.appending(path: "delta-verify-\(UUID().uuidString).app")
        defer { try? FileManager.default.removeItem(at: staging) }
        let header = try DeltaArchive.Header.decode(built.data)
        let fileStart = DeltaArchive.Header.size + header.tocLength + plan.rangeOffset
        let slice = built.data.subdata(in: fileStart ..< (fileStart + plan.rangeLength))
        try DeltaArchive.stage(toc: built.toc, plan: plan, payload: slice, running: source.bundle, staging: staging)
    }
    return
        "\(output.path): \(built.data.count) bytes, tocSHA256=\(built.tocSHA256), sources=\(built.toc.sources.keys.sorted().joined(separator: ","))"
}

func makeIndex(_ words: [String]) throws -> String? {
    guard words.count >= 5, let build = Int(words[2]) else { return nil }
    let tag = words[1]
    let notesData = try Data(contentsOf: URL(filePath: words[3]))
    let output = URL(filePath: words[4])
    var variants: [ReleaseIndex.Variant] = []
    for spec in words.dropFirst(5) {
        let parts = spec.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4, let flavour = parseFlavour(parts[0]) else { return nil }
        let arch = parts[1]
        let zipURL = URL(filePath: parts[2])
        let zipData = try Data(contentsOf: zipURL, options: .mappedIfSafe)
        var deltasName: String?
        var deltasSize: Int?
        var deltasTOCSHA256: String?
        if !parts[3].isEmpty {
            let deltasURL = URL(filePath: parts[3])
            let deltasData = try Data(contentsOf: deltasURL, options: .mappedIfSafe)
            let header = try DeltaArchive.Header.decode(deltasData)
            deltasName = deltasURL.lastPathComponent
            deltasSize = deltasData.count
            deltasTOCSHA256 = header.tocSHA256
        }
        variants.append(
            ReleaseIndex.Variant(
                flavour: flavour,
                architecture: arch,
                archiveName: zipURL.lastPathComponent,
                archiveSize: zipData.count,
                archiveSHA256: BundleManifest.hex(zipData),
                deltasName: deltasName,
                deltasSize: deltasSize,
                deltasTOCSHA256: deltasTOCSHA256
            )
        )
    }
    let nowSeconds = Int64(Date.now.timeIntervalSince1970)
    let expiresAt = nowSeconds + Int64(ReleaseIndex.defaultLifetime)
    let index = ReleaseIndex(
        tag: tag,
        build: build,
        notesSHA256: BundleManifest.hex(notesData),
        issuedAt: nowSeconds,
        expiresAt: expiresAt,
        variants: variants
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let encoded = try encoder.encode(index)
    try encoded.write(to: output)
    return "\(output.path): \(encoded.count) bytes, \(variants.count) variant(s)"
}

func run(_ words: [String]) throws -> String? {
    let urls = words.dropFirst().map { URL(filePath: $0) }
    switch (words.first, words.count) {
        case ("make", 4):
            let delta = try BinaryDelta.make(from: Data(contentsOf: urls[0]), to: Data(contentsOf: urls[1]))
            try delta.write(to: urls[2])
            return "\(urls[2].path): \(delta.count) bytes"
        case ("apply", 4):
            try BinaryDelta.apply(Data(contentsOf: urls[1]), to: Data(contentsOf: urls[0])).write(to: urls[2])
            return urls[2].path
        case ("package", 6):
            guard let from = Int(words[3]), let to = Int(words[4]) else { return nil }
            let package = try UpdatePackage.make(old: urls[0], new: urls[1], from: from, to: to)
            try package.write(to: urls[4])
            return "\(urls[4].path): \(package.count) bytes"
        case ("stage", 4):
            let package = try UpdatePackage(decoding: Data(contentsOf: urls[0]))
            try UpdateStaging.build(package, running: urls[1], staging: urls[2])
            return "\(urls[2].path): build \(package.to), every file as its manifest says"
        case ("verify", 3):
            let left = try BundleManifest.read(bundle: urls[0])
            let right = try BundleManifest.read(bundle: urls[1])
            guard left == right else {
                FileHandle.standardError.write(Data("SunsetDeltaTool: manifests differ\n".utf8))
                exit(1)
            }
            return "manifests match (\(left.entries.count) entries)"
        case ("archive", _):
            return try makeArchive(words)
        case ("index", _):
            return try makeIndex(words)
        default:
            return nil
    }
}

do {
    guard let said = try run(words) else {
        FileHandle.standardError.write(Data(usage.utf8))
        exit(64)
    }
    print(said)
} catch {
    FileHandle.standardError.write(Data("SunsetDeltaTool: \(error)\n".utf8))
    exit(1)
}
