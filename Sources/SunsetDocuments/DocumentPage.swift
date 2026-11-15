internal import Foundation
public import MarkdownLookKit
public import Observation

/// The rendered page of a document (roadmap 0023 step M-c), one for every pane that shows it. Measured at step M-b: a page
/// costs 3.5 ms at 20 KB and 330 ms at 2 MB, so it is made only while a pane has it on screen; at once on the main actor for
/// a short text (no empty frame, no flicker), and off it for a long one, where what is typed while a page is being made makes
/// one more page after it and not one for each key.
@MainActor @Observable
public final class DocumentPage {
    /// The longest text (UTF-16 units) whose page is made at once on the main actor: about 5 ms.
    public static let inlineLimit = 32_768

    /// The page as it was last made: of the text as it is, or of a moment ago while the next is being made.
    public private(set) var shown = NativeDocument()
    /// How many pages were made.
    @ObservationIgnored public private(set) var made = 0

    @ObservationIgnored private let source: MarkdownSource
    @ObservationIgnored private let inlineLimit: Int
    @ObservationIgnored private let maker: @Sendable (DocumentPageSnapshot) async -> NativeDocument
    /// The panes that show the page rendered, and whether each is on screen.
    @ObservationIgnored private var interest: [ObjectIdentifier: Bool] = [:]
    /// The text and the settings `shown` was made from.
    @ObservationIgnored private var madeFrom: Stamp?
    /// A change was told and is about to be looked at (observation tells it before the value is there).
    @ObservationIgnored private var hop: Task<Void, Never>?
    @ObservationIgnored private var running: Task<Void, Never>?
    @ObservationIgnored private var again = false

    private struct Stamp: Equatable {
        var revision: Int
        var settings: ViewerSettings
    }

    /// - Parameters:
    ///   - source: the text.
    ///   - inlineLimit: the longest text whose page is made at once.
    ///   - maker: makes a page off the main actor (a test holds it to see what happens meanwhile).
    public init(
        source: MarkdownSource,
        inlineLimit: Int = DocumentPage.inlineLimit,
        maker: @escaping @Sendable (DocumentPageSnapshot) async -> NativeDocument = DocumentPage.makeConcurrently
    ) {
        self.source = source
        self.inlineLimit = inlineLimit
        self.maker = maker
        follow()
    }

    /// The page of `snapshot`.
    /// - Complexity: O(the document).
    public nonisolated static func make(_ snapshot: DocumentPageSnapshot) -> NativeDocument {
        switch snapshot.content {
            case .markdown: snapshot.session.nativeDocument(settings: snapshot.settings)
            case .diagram: NativeDocument(diagram: snapshot.session.text, settings: snapshot.settings)
            case .plain: NativeDocument()
        }
    }

    @concurrent
    public nonisolated static func makeConcurrently(_ snapshot: DocumentPageSnapshot) async -> NativeDocument {
        make(snapshot)
    }

    /// What `pane` wants of the page: true, it shows it and is on screen; false, it shows it in a tab that is not; nil, it no
    /// longer shows it. With no pane left the page is let go.
    public func setInterest(_ wanted: Bool?, of pane: AnyObject) {
        interest[ObjectIdentifier(pane)] = wanted
        if interest.isEmpty {
            running?.cancel()
            running = nil
            again = false
            madeFrom = nil
            if !shown.rows.isEmpty { shown = NativeDocument() }
        } else {
            refresh()
        }
    }

    /// Waits until the page is of the text as it is (or nothing is being made).
    public func settled() async {
        while hop != nil || running != nil {
            await hop?.value
            await running?.value
        }
    }

    // MARK: Following the text

    private func follow() {
        withObservationTracking {
            _ = source.revision
            _ = source.settings
        } onChange: { [weak self] in
            // Told where the text is changed, which is the main actor (the source is bound to it), and before the new value is in
            // place: looked at in the next turn.
            MainActor.assumeIsolated { self?.changed() }
        }
    }

    private func changed() {
        guard hop == nil else { return }
        hop = Task { [weak self] in
            self?.hop = nil
            self?.follow()
            self?.refresh()
        }
    }

    private func refresh() {
        guard source.content != .plain, interest.values.contains(true) else { return }
        let stamp = Stamp(revision: source.revision, settings: source.settings)
        guard stamp != madeFrom else { return }
        let snapshot = DocumentPageSnapshot(content: source.content, session: source.session, settings: stamp.settings)
        if source.storage.length <= inlineLimit {
            running?.cancel()
            running = nil
            again = false
            take(Self.make(snapshot), from: stamp)
            return
        }
        guard running == nil else {
            again = true
            return
        }
        running = Task { [weak self, maker] in
            let page = await maker(snapshot)
            guard !Task.isCancelled, let self else { return }
            self.running = nil
            self.take(page, from: stamp)
            if self.again {
                self.again = false
                self.refresh()
            }
        }
    }

    private func take(_ page: NativeDocument, from stamp: Stamp) {
        shown = page
        madeFrom = stamp
        made += 1
    }
}
