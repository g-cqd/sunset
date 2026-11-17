# How VMRunner explains itself, and what Sunset would take from it (2026-11-17)

Asked by the owner on 2026-11-17: "investigate the vmrunner project on this computer and how the help is constructed and
investigate how to bring this helper logic to sunset so that we can display tooltip and help across the whole app".
Read from VMRunner's source at 092d218 (2026-10-26); nothing of it is copied here, and nothing below is probed in Sunset.

## What VMRunner has

| Part | Where | What it is |
|---|---|---|
| Topics | `Help/HelpTopic.swift` | `HelpTopic`, one enum case per thing explained (62), grouped in `HelpArea`s (10) |
| Text | `Help/HelpContent+*.swift` (8 files, ~1,500 lines) | `HelpCatalog.entries: [HelpTopic: HelpEntry]`; an entry is a title, a **one-sentence summary** (the tooltip), plain paragraphs ("• " a list item; inline Markdown), paragraphs "for experienced users" folded away, related topics |
| Search | `HelpCatalog.search` | every word of the query in the title, summary and text, lower-cased, from an index built once |
| A row's help | `View.settingHelp(_:)` (59 uses), `HelpHeader` (28), `HelpButton` (10) | the row's `.help(summary)` tooltip and a trailing "?" that opens a popover with the plain text, the expert part folded, and "Open in Help" |
| The Help window | `HelpWindowView`, `HelpNavigator` | a `Window` scene: topics by area with a search field, the topic on the right with its expert part open and its related topics; the Help menu is replaced by it |
| Its gates | `Tests/VMRunnerTests/HelpTests.swift` | every topic has text and no text is orphaned; a summary is a sentence of 110 characters at most; titles unique; related topics exist and are not the topic itself; every area has a topic; some topics must name given settings or say what is impossible |

What makes it work: **one source for the tooltip and the explanation** (the summary is the tooltip), **topics are a closed
enum** so a test sees a missing text, and **the plain text and the expert text are kept apart**.

## What Sunset has now

- 36 `.help(…)` tooltips written where they are used, each its own sentence; no topic, no link between them.
- 32 settings with a `.noted(…)` line under them (`SettingsOption.note`), shown in Settings only.
- Settings are found by words (`SettingsOption` keywords; the Library's Settings search).
- No Help menu of its own, no help window, no "?".

## What it would take (a proposal; not decided)

1. **`HelpTopic` and `HelpCatalog` in a module the UI modules share** (the shell's, not the core: white paper's core
   imports no UI). One summary per topic (the tooltip, a sentence of at most 110 characters, as VMRunner's gate), plain
   paragraphs, the expert part, related topics.
2. **Tooltips from topics.** A modifier, say `.helpTopic(.keepAwake)`, setting `.help(summary)` and, on rows and settings,
   a "?" opening a popover. The 36 `.help` strings become topics or stay as plain tooltips where there is nothing more to
   say (a button's name); a gate: no `.help("…")` literal in a view outside a short list, as the design-token gate does for
   measures.
3. **Settings take their notes from topics.** `SettingsOption.noted` names a topic; its summary is the note, its text the
   popover. One text, two places.
4. **Help in Sunset's own place.** A Help section in the Library (beside History, Documents, Downloads, Settings),
   searchable as Settings are, rather than a separate window: it fits the sidebar's model. The Help menu opens it.
5. **Gates as VMRunner's**: every topic has text, summaries are short sentences, related topics exist; and Sunset's own:
   anything an untrusted program can ask (white paper §9) has a topic that says the policy.

## Questions for the owner before any of it

- A Help section in the Library, or a window of its own as VMRunner's?
- A "?" beside rows and settings, or tooltips only (Sunset's sidebar has little room)?
- Which first: the settings (the notes exist), the sidebar's controls, or the web's permissions and policies?
