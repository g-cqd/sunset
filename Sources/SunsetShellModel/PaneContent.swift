package import CoreGraphics
package import SunsetPane

/// What is in a pane, as the tabs, the sidebar and the pane area see it: a terminal, a note, later a page or a document. The shell knows nothing else
/// of it (docs/research/pane-content-2026-11-11.md).
@MainActor package protocol PaneContent: AnyObject {
    /// What the program or the document calls itself.
    var title: String { get }
    /// A second line under the title: a directory, an address.
    var detail: String? { get }
    /// The tab's own picture, when the person gave it none.
    var glyph: PaneGlyph { get }
    /// More words it is found by when tabs are searched, beside its title and detail (a terminal: the program in front).
    var searchTerms: [String] { get }
    /// Types a command into it as if typed, then Return, as soon as it can take one (a terminal: once its shell has drawn its prompt). Kinds that run
    /// nothing ignore it.
    func type(command: String)
    /// Activity to show under the title, 0 to 1; nil when there is none.
    var progress: Double? { get }
    /// A command runs in it, in front of its shell (a terminal): what a tab kept awake until its command ends waits for.
    /// Read often: it does not ask the system, unlike `closeWarning`.
    var runsCommand: Bool { get }
    /// Why closing it now would lose something (a command is running), asked at the moment of closing; nil when it can go at once. Not the same thing
    /// as `progress`: a page that loads can be closed, a command that prints nothing cannot.
    var closeWarning: String? { get }
    /// It captures the camera, microphone or screen (a web page): a dot on its tab, of this colour.
    var captureMark: PaneCaptureMark? { get }
    /// The colour of what the pane shows (a site's theme or icon colour), for a tab coloured by it; nil: none.
    var siteColor: [UInt8]? { get }
    /// It plays sound, or is muted (a web page): a speaker on its tab; nil for silence.
    var sound: PaneSound? { get }
    /// Mutes it, or lets it be heard again.
    func toggleMuted()
    /// The profile it was loaded as, when it is not its Space's (Reload As): its tab shows its name.
    var profileMark: String? { get }
    /// The microphone and the camera it uses (a web page): each on its tab, muted from there.
    var devices: PaneCapture { get }
    /// Mutes a device it uses, or turns it back on.
    func toggle(_ device: PaneCapture.Device)
    /// It has edits that are not saved (a document): a dot on its tab.
    var isEdited: Bool { get }
    /// Its unsaved edits, when closing it could lose some: asked about before it closes (`TabsModel.losingNothing`).
    var unsaved: UnsavedEdits? { get }
    /// Nothing of it is kept: not in the session, not restored (a private page).
    var isPrivate: Bool { get }
    /// How to bring it back in another run.
    var descriptor: PaneDescriptor { get }
    /// It ended by itself (the shell exited): the pane closes.
    var onExit: () -> Void { get set }
    /// Its view took the keyboard (it was clicked): its pane is the focused one.
    var onFocusRequest: () -> Void { get set }
    /// Whether it has the keyboard and whether it is on screen (a tab that is not selected is neither).
    func setState(focused: Bool, visible: Bool)
    /// The pane is closing: whatever runs for it ends.
    func stop()
    /// Its last picture, for a window that shows it while another draws it and for its tab's preview (a page's snapshot); nil
    /// when it has none. Kinds that draw their own (a terminal's last surface) leave it nil.
    var picture: CGImage? { get }
    /// Takes its picture now, as it leaves a window or is hidden (J); kinds without one ignore it.
    func takePicture()
    /// Gets ready to be shown, without showing (its row is pointed at): a page not made yet starts loading. Kinds that
    /// are ready at once ignore it.
    func prepare()
    /// It let go of its memory while hidden and is made again when shown (a page, S-f): its icon is dimmed.
    var isUnloaded: Bool { get }
    /// A page with no address yet (a new tab's): the command bar opens on it.
    var isBlankPage: Bool { get }
    /// What it adds to its tab's menu (a page: Reload, Copy Address, Site Settings).
    var menuActions: [PaneMenuAction] { get }
}

extension PaneContent {
    package var searchTerms: [String] {
        []
    }
    package func type(command: String) {}
    /// Shared into a call, whatever its kind (`SharedPanes`); a content that captures overrides it.
    package var captureMark: PaneCaptureMark? {
        SharedPanes.shared.mark(self)
    }

    package var siteColor: [UInt8]? {
        nil
    }
    package var sound: PaneSound? {
        nil
    }
    package func toggleMuted() {}
    package var devices: PaneCapture {
        PaneCapture()
    }
    package var profileMark: String? {
        nil
    }
    package func toggle(_ device: PaneCapture.Device) {}
    package var isPrivate: Bool {
        false
    }
    package var isEdited: Bool {
        false
    }
    package var unsaved: UnsavedEdits? {
        nil
    }
    package var picture: CGImage? {
        nil
    }
    package var runsCommand: Bool {
        false
    }
    package func takePicture() {}
    package func prepare() {}
    package var isUnloaded: Bool {
        false
    }
    package var menuActions: [PaneMenuAction] {
        []
    }
    package var isBlankPage: Bool {
        false
    }
}
