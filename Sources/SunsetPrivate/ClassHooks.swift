internal import Foundation
internal import ObjectiveC

/// Methods added to a delegate's class at run time, once a class (`WebPermissionHooks` and `WebDownloadHooks` each kept
/// the classes they had done and added the same way).
@MainActor
enum ClassHooks {
    private static var done: Set<String> = []

    /// Whether `group` was not yet added to `cls`; true once, then false.
    static func first(_ group: String, on cls: AnyClass) -> Bool {
        done.insert(group + "\u{0}" + NSStringFromClass(cls)).inserted
    }

    /// Adds `name`, run by `block`, with the Objective-C `types`.
    static func add(_ name: String, _ block: Any, _ types: String, to cls: AnyClass) {
        _ = unsafe class_addMethod(cls, NSSelectorFromString(name), imp_implementationWithBlock(block), types)
    }
}
