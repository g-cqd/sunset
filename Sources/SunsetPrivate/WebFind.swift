public import Foundation
internal import InternedStrings
internal import ObjectiveC

/// WebKit's own find in page, the one Safari uses (web step d): every match highlighted, their count and the index of the current one. Not public
/// API: the selectors are looked up by name (`responds(to:)`) and `isAvailable` is false when a macOS drops them; the caller then uses the public
/// `WKWebView.find` (no count). The answers come to a listener whose methods are added at run time, so no private name is written in plain.
@MainActor
public final class WebFind: NSObject {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let caseInsensitive = Options(rawValue: 1 << 0)
        public static let atWordStarts = Options(rawValue: 1 << 1)
        public static let backwards = Options(rawValue: 1 << 3)
        public static let wrapAround = Options(rawValue: 1 << 4)
        public static let showFindIndicator = Options(rawValue: 1 << 6)
        public static let showHighlight = Options(rawValue: 1 << 7)
        public static let noIndexChange = Options(rawValue: 1 << 8)
        public static let determineMatchIndex = Options(rawValue: 1 << 9)
    }

    /// The answer to a search: how many matches, and which one is current (nil when not known); 0 matches: not found.
    public var onResult: (_ count: Int, _ index: Int?) -> Void = { _, _ in }

    private typealias FindCall = @convention(c) (AnyObject, Selector, NSString, UInt, UInt) -> Void
    private typealias HideCall = @convention(c) (AnyObject, Selector) -> Void
    private typealias SetDelegate = @convention(c) (AnyObject, Selector, AnyObject?) -> Void

    private weak var view: NSObject?

    private static let findName = #Interned("_findString:options:maxCount:")
    private static let hideName = #Interned("_hideFindUI")
    private static let delegateName = #Interned("_setFindDelegate:")

    /// Whether `view` (a `WKWebView`) answers WebKit's private find.
    public static func isAvailable(on view: NSObject) -> Bool {
        view.responds(to: NSSelectorFromString(findName)) && view.responds(to: NSSelectorFromString(delegateName))
    }

    /// A find for `view`, or nil when its WebKit does not have the private find.
    public init?(view: NSObject) {
        guard Self.isAvailable(on: view) else { return nil }
        self.view = view
        super.init()
        Self.installAnswers()
        call(Self.delegateName, as: SetDelegate.self) { function, target, selector in function(target, selector, self) }
    }

    /// Looks for `text`, from the current match on (`.backwards` the other way), highlighting every match.
    public func find(_ text: String, options: Options) {
        let all: Options = options.union([.wrapAround, .showFindIndicator, .showHighlight, .determineMatchIndex])
        call(Self.findName, as: FindCall.self) { function, target, selector in
            function(target, selector, text as NSString, all.rawValue, 1_000)
        }
    }

    /// Takes the highlights away.
    public func hide() {
        call(Self.hideName, as: HideCall.self) { function, target, selector in function(target, selector) }
    }

    private func call<Function>(_ name: String, as type: Function.Type, _ body: (Function, AnyObject, Selector) -> Void)
    {
        let selector = NSSelectorFromString(name)
        guard let view, view.responds(to: selector) else { return }
        let implementation = view.method(for: selector)
        body(unsafe unsafeBitCast(implementation, to: type), view, selector)
    }

    // MARK: The answers

    fileprivate func answered(count: Int, index: Int?) { onResult(count, index) }

    private static var installed = false

    /// `-_webView:didCountMatches:forString:`, `-_webView:didFindMatches:forString:withMatchIndex:`, `-_webView:didFailToFindString:`.
    private static func installAnswers() {
        guard !installed else { return }
        installed = true
        let found: @convention(block) (WebFind, AnyObject, UInt, NSString, Int) -> Void = {
            finder,
            _,
            count,
            _,
            index in
            MainActor.assumeIsolated { finder.answered(count: Int(count), index: index >= 0 ? index : nil) }
        }
        let counted: @convention(block) (WebFind, AnyObject, UInt, NSString) -> Void = { finder, _, count, _ in
            MainActor.assumeIsolated { finder.answered(count: Int(count), index: nil) }
        }
        let failed: @convention(block) (WebFind, AnyObject, NSString) -> Void = { finder, _, _ in
            MainActor.assumeIsolated { finder.answered(count: 0, index: nil) }
        }
        add(#Interned("_webView:didFindMatches:forString:withMatchIndex:"), found, types: "v@:@Q@q")
        add(#Interned("_webView:didCountMatches:forString:"), counted, types: "v@:@Q@")
        add(#Interned("_webView:didFailToFindString:"), failed, types: "v@:@@")
    }

    private static func add(_ name: String, _ block: Any, types: String) {
        let implementation = imp_implementationWithBlock(block)
        _ = unsafe class_addMethod(WebFind.self, NSSelectorFromString(name), implementation, types)
    }
}
