import Foundation
import Testing

@testable import SunsetWeb

@Suite("What a page may ask in a dialog") @MainActor struct PageDialogTests {
    @Test func `the first dialog of a page is shown plainly; from the second the panel offers to silence the page`() {
        var policy = PageDialogPolicy()
        #expect(policy.next() == .show(offersSilence: false))
        #expect(policy.next() == .show(offersSilence: true))
        #expect(policy.next() == .show(offersSilence: true))
    }

    @Test func `a silenced page's dialogs are not shown, until the page is left`() {
        var policy = PageDialogPolicy()
        _ = policy.next()
        policy.silence()
        #expect(policy.next() == .suppress && policy.next() == .suppress)
        policy.pageLeft()
        #expect(policy.next() == .show(offersSilence: false))
    }

    @Test func `a dialog answers once; what it says is cut to a length and named by its host`() {
        var replies: [PageDialog.Reply] = []
        let long = String(repeating: "x", count: 5000)
        let dialog = PageDialog(kind: .prompt(defaultText: "a"), host: "", message: long, offersSilence: false) {
            replies.append($0)
        }
        #expect(dialog.message.count == PageDialog.messageLimit + 1 && dialog.message.hasSuffix("\u{2026}"))
        #expect(dialog.title == "This page says")
        dialog.answer(.ok("typed"))
        dialog.answer(.cancel)
        #expect(replies == [.ok("typed")])
        let named = PageDialog(kind: .alert, host: "news.com", message: "hi", offersSilence: true) { _ in }
        #expect(named.title == "news.com says" && named.message == "hi")
    }

    @Test func `a page's dialog waits in the page; silenced, confirm is refused and prompt gives nothing`() async {
        let page = WebContent(url: nil, settings: WebSettings())
        async let first = page.ask(.confirm, message: "sure?", host: "a.com")
        while page.dialog == nil { await Task.yield() }
        #expect(page.dialog?.kind == .confirm && page.dialog?.offersSilence == false)
        page.dialog?.answer(.ok(nil))
        #expect(await first == .ok(nil) && page.dialog == nil)

        async let second = page.ask(.alert, message: "again", host: "a.com")
        while page.dialog == nil { await Task.yield() }
        #expect(page.dialog?.offersSilence == true)
        page.silenceDialogs()
        #expect(await second == .cancel && page.dialog == nil)
        #expect(await page.ask(.prompt(defaultText: ""), message: "more", host: "a.com") == .cancel)
    }

    @Test func `a page that is closed answers its waiting dialog`() async {
        let page = WebContent(url: nil, settings: WebSettings())
        async let waiting = page.ask(.alert, message: "x", host: "a.com")
        while page.dialog == nil { await Task.yield() }
        page.stop()
        #expect(await waiting == .cancel)
    }
}
