public import Foundation
internal import InternedStrings
internal import ObjectiveC

/// WebKit's private permission questions and switches (web step g): screen sharing (`getDisplayMedia`), the Notification API, and whether a navigation
/// came from a click. Not public API: looked up by name, added to the delegate's class at run time; where WebKit no longer has them nothing is added,
/// the switches stay off, and a page cannot share its screen or notify.
@MainActor
public enum WebPermissionHooks {
    /// A question to answer: the delegate it was asked of, the web view, the security origin (a `WKSecurityOrigin`), and the answer to give once.
    public typealias Question = (
        _ delegate: AnyObject, _ webView: AnyObject, _ origin: AnyObject, _ decide: @escaping (Bool) -> Void
    ) -> Void

    private static var installed: Set<ObjectIdentifier> = []

    /// Adds the screen and notification questions to `delegateClass` (a `WKUIDelegate`'s class), once.
    public static func install(
        on delegateClass: AnyClass,
        screen: @escaping Question,
        notifications: @escaping Question
    ) {
        guard installed.insert(ObjectIdentifier(delegateClass)).inserted else { return }
        let display:
            @convention(block) (
                AnyObject, AnyObject, AnyObject, AnyObject?, Bool, @escaping @convention(block) (Int) -> Void
            ) -> Void = {
                delegate,
                webView,
                origin,
                _,
                _,
                handler in
                MainActor.assumeIsolated { screen(delegate, webView, origin) { handler($0 ? 1 : 0) } }
            }
        let notify:
            @convention(block) (AnyObject, AnyObject, AnyObject, @escaping @convention(block) (Bool) -> Void) -> Void =
                {
                    delegate,
                    webView,
                    origin,
                    handler in
                    MainActor.assumeIsolated { notifications(delegate, webView, origin) { handler($0) } }
                }
        add(
            #Interned(
                "_webView:requestDisplayCapturePermissionForOrigin:initiatedByFrame:withSystemAudio:decisionHandler:"
            ),
            display,
            "v@:@@@B@?",
            to: delegateClass
        )
        add(
            #Interned("_webView:requestNotificationPermissionForSecurityOrigin:decisionHandler:"),
            notify,
            "v@:@@@?",
            to: delegateClass
        )
    }

    private typealias GetFlag = @convention(c) (AnyObject, Selector) -> Bool
    private typealias SetFlag = @convention(c) (AnyObject, Selector, Bool) -> Void

    /// Turns on the preferences that let pages ask for screen sharing and notifications, through their setters (key-value coding would take
    /// "_screenCaptureEnabled" for an instance variable and write into the object: it did, and the app crashed at launch).
    public static func enable(on preferences: NSObject) {
        for name in [#Interned("_setScreenCaptureEnabled:"), #Interned("_setNotificationsEnabled:")] {
            let selector = NSSelectorFromString(name)
            guard preferences.responds(to: selector) else { continue }
            let setter = unsafe unsafeBitCast(preferences.method(for: selector), to: SetFlag.self)
            setter(preferences, selector, true)
        }
    }

    /// Whether WebKit says the navigation came from a click or a key; nil when it does not say (the caller decides then).
    public static func isUserInitiated(_ action: NSObject) -> Bool? {
        let selector = NSSelectorFromString(#Interned("_isUserInitiated"))
        guard action.responds(to: selector) else { return nil }
        let getter = unsafe unsafeBitCast(action.method(for: selector), to: GetFlag.self)
        return getter(action, selector)
    }

    private static func add(_ name: String, _ block: Any, _ types: String, to cls: AnyClass) {
        _ = unsafe class_addMethod(cls, NSSelectorFromString(name), imp_implementationWithBlock(block), types)
    }
}
