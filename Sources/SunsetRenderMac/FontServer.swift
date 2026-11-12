internal import Foundation

/// One font made at a time in this process. Fonts made from several threads at once (the tests run in parallel, and a window's terminals each
/// make theirs) left every one of those threads waiting on the font server for good (seen three times on 2026-11-12, macOS 27.0.1: all in
/// `XTCopyPropertiesForFont…` under `CTFontCreateCopyWithSymbolicTraits` and `CTFontCopyFamilyName`). Making a font takes milliseconds.
enum FontServer {
    static let lock = NSRecursiveLock()
}
