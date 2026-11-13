package import Foundation

/// A page that could not be opened (the owner's answer: a plain page of ours with the reason, the address and Try Again; Visit Anyway after a warning for
/// a certificate the system does not trust).
package struct WebFailure: Sendable, Equatable {
    package let url: URL?
    package let reason: String
    package let isCertificate: Bool
    /// What the failure page is headed with.
    package let heading: String

    /// The errors that are a certificate the system refuses.
    static let certificateCodes: Set<Int> = [
        NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid, NSURLErrorSecureConnectionFailed
    ]

    /// A page whose process ended (roadmap 0029 step 5).
    static func processEnded(url: URL?) -> WebFailure {
        WebFailure(url: url, heading: "This page stopped", reason: "Its process ended. Try Again loads it afresh.")
    }

    private init(url: URL?, heading: String, reason: String) {
        self.url = url
        self.heading = heading
        self.reason = reason
        isCertificate = false
    }

    /// The failure an error means; nil for what is not one (a load replaced by another, a download).
    package init?(_ error: any Error, url: URL?) {
        let error = error as NSError
        if error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled { return nil }
        // WebKit's "frame load interrupted" (a navigation turned into a download or cancelled by a policy).
        if error.domain == "WebKitErrorDomain", error.code == 102 { return nil }
        self.url = (error.userInfo[NSURLErrorFailingURLErrorKey] as? URL) ?? url
        reason = error.localizedDescription
        heading = "Sunset could not open this page"
        isCertificate = error.domain == NSURLErrorDomain && Self.certificateCodes.contains(error.code)
    }
}
