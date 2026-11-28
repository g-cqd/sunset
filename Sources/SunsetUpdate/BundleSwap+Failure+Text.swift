public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name; where macOS refused, what to do.
extension BundleSwap.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .refused(let code):
                let said = String(cString: strerror(code))
                let denied = code == EPERM || code == EACCES
                return "Sunset could not replace itself (error \(code): \(said))."
                    + (denied
                        ? " Allow it in System Settings › Privacy & Security › App Management, or install the new "
                            + "version from its releases page."
                        : "")
        }
    }
}
