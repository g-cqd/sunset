public import Foundation
import Synchronization

/// Bounded, secret-free, JSON-Lines security event log for enterprise SIEM export (R-OPS-1 / Sprint 3).
/// Records security-relevant lifecycle events (vault unlocks/locks, certificate exceptions, extension installs/refusals,
/// update verifications/refusals, managed-policy clamps) without ever accepting secrets, passwords, cookies, or tokens.
public final class SecurityAuditLog: Sendable {
    /// Structured security event category (SIEM JSONL `kind` field).
    public struct Kind: RawRepresentable, Codable, Equatable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static func vault(_ event: String) -> Self {
            Self(rawValue: "vault.\(event)")
        }

        public static func web(_ event: String) -> Self {
            Self(rawValue: "web.\(event)")
        }

        public static func update(_ event: String) -> Self {
            Self(rawValue: "update.\(event)")
        }

        public static func policy(_ event: String) -> Self {
            Self(rawValue: "policy.\(event)")
        }
    }

    public struct Entry: Codable, Equatable, Sendable {
        public let timestamp: String
        public let kind: Kind
        public let outcome: String
        /// Short non-sensitive metadata (host, build number, rule key — never secrets or URLs with query strings).
        public let attributes: [String: String]

        public init(timestamp: String, kind: Kind, outcome: String, attributes: [String: String] = [:]) {
            self.timestamp = timestamp
            self.kind = kind
            self.outcome = outcome
            self.attributes = attributes
        }
    }

    /// Maximum log file size in bytes before automatic rotation (`security-audit.jsonl` -> `.1.jsonl`): 1 MiB.
    public static let maximumFileBytes = 1 << 20
    /// Maximum length per attribute value to keep entries strictly bounded.
    public static let maximumAttributeLength = 160

    public let fileURL: URL
    private let lock = Mutex(())

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Appends one sanitized JSONL entry to `fileURL` (mode `0600`), rotating when `maximumFileBytes` is reached.
    public func record(
        _ kind: Kind,
        outcome: String,
        attributes: [String: String] = [:],
        at timestamp: Date
    ) {
        let iso = ISO8601DateFormatter().string(from: timestamp)
        let bounded = attributes.mapValues { Self.sanitize($0) }
        let entry = Entry(timestamp: iso, kind: kind, outcome: Self.sanitize(outcome), attributes: bounded)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard var line = try? encoder.encode(entry) else { return }
        line.append(0x0A)
        lock.withLock { _ in
            Self.append(line, to: fileURL)
        }
    }

    /// Reads all valid entries currently stored in `fileURL` (for SIEM export or inspection).
    public func readEntries() -> [Entry] {
        lock.withLock { _ in
            guard let data = try? Data(contentsOf: fileURL) else { return [] }
            let decoder = JSONDecoder()
            return data.split(separator: 0x0A)
                .compactMap { slice in
                    try? decoder.decode(Entry.self, from: Data(slice))
                }
        }
    }

    private static func sanitize(_ value: String) -> String {
        let singleLine =
            value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return String(singleLine.prefix(maximumAttributeLength))
    }

    private static func append(_ line: Data, to url: URL) {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if let size = (try? fm.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue,
            size + line.count > maximumFileBytes
        {
            let rotated = url.deletingPathExtension().appendingPathExtension("1.jsonl")
            try? fm.removeItem(at: rotated)
            try? fm.moveItem(at: url, to: rotated)
        }
        if !fm.fileExists(atPath: url.path) {
            fm.createFile(atPath: url.path, contents: line, attributes: [.posixPermissions: 0o600])
            return
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        }
    }
}
