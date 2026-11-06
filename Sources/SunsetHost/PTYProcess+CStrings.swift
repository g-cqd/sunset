internal import Darwin

extension PTYProcess {
    /// Calls `body` with a NULL-terminated array of C strings for `strings`, valid during the call.
    static func withCStrings<R>(_ strings: [String], _ body: (UnsafePointer<UnsafeMutablePointer<CChar>?>) -> R) -> R {
        var pointers: [UnsafeMutablePointer<CChar>?] = strings.map { unsafe strdup($0) }
        pointers.append(nil)
        defer { for pointer in pointers { unsafe free(pointer) } }
        return pointers.withUnsafeBufferPointer { buffer in
            // The array holds its terminator at least, so it has a base address.
            unsafe body(buffer.baseAddress.unsafelyUnwrapped)
        }
    }
}
