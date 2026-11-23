package import Foundation

/// The certificates a page was told to trust anyway (Visit Anyway), each for its host: only the one the person was shown
/// (the outside audit's HIGH-04: by host alone, any certificate an attacker presented later was trusted too). Kept for the
/// page's life, never written.
package struct CertificateExceptions: Sendable, Equatable {
    private var accepted: [String: Set<Data>] = [:]

    package init() {}

    package mutating func accept(host: String, certificate: Data) {
        accepted[host.lowercased(), default: []].insert(certificate)
    }

    package func accepts(host: String, certificate: Data?) -> Bool {
        guard let certificate else { return false }
        return accepted[host.lowercased()]?.contains(certificate) == true
    }
}
