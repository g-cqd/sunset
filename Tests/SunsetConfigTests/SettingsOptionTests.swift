import Testing

@testable import SunsetConfig

/// The options of Settings, declared once (the review of 2026-11-15, section 5; task t268): the file's key, the title, the words
/// it is found by, where it is shown and what control it has.
@Suite("The options of Settings") struct SettingsOptionTests {
    let options = SettingsOption.all

    @Test func `every key of the file has a control, and one only`() {
        var owners: [String: [String]] = [:]
        for option in options {
            for key in option.keys { owners[key, default: []].append(option.id) }
        }
        let missing = ConfigurationKeys.all.filter { owners[$0] == nil }
        #expect(missing.isEmpty, "keys with no control: \(missing)")
        let twice = owners.filter { $0.value.count > 1 }
        #expect(twice.isEmpty, "keys with several controls: \(twice)")
        let unknown = owners.keys.filter { !ConfigurationKeys.all.contains($0) }.sorted()
        #expect(unknown.isEmpty, "not keys of the file: \(unknown)")
    }

    @Test func `an option is named as the file names it`() {
        #expect(Set(options.map(\.id)).count == options.count, "an identifier is used twice")
        let others = options.filter { $0.keys != [$0.id] }.map(\.id).sorted()
        #expect(others == ["file.location", "web.permissions"], "only these are not one key of the file: \(others)")
        #expect(options.allSatisfy { !$0.title.isEmpty && !$0.pane.isEmpty })
    }

    @Test func `a switch, a number and a choice each change the key they are declared for`() {
        for option in options where option.keys == [option.id] {
            var changed = Configuration()
            switch option.control {
                case .toggle(let value, _): value.set(&changed, !value.get(changed))
                case .number(let value, let range, _, _, _):
                    value.set(&changed, value.get(changed) == range.lowerBound ? range.upperBound : range.lowerBound)
                case .choice(let choice, _):
                    let other = choice.items.first { $0.value != choice.get(changed) }
                    guard let other else { continue }
                    choice.set(&changed, other.value)
                    #expect(choice.get(changed) == other.value, "\(option.id) did not take \(other.value)")
                case .text(let value, _): value.set(&changed, value.get(changed) + "x")
                default: continue
            }
            let before = ConfigurationWriter.literals(for: Configuration())
            let after = ConfigurationWriter.literals(for: changed)
            let moved = before.keys.filter { before[$0] != after[$0] }.sorted()
            #expect(moved == [option.id], "\(option.id) changed \(moved)")
        }
    }

    @Test func `the search entries are the options`() {
        let entries = SettingsOption.all.map(\.entry)
        #expect(SettingsSearch.matches("scrollback", in: entries).first?.id == "scrollback.lines")
        #expect(SettingsSearch.matches("osc 52", in: entries).map(\.id) == ["terminal.clipboardWrite"])
        #expect(SettingsSearch.matches("download folder", in: entries).first?.id == "web.downloadFolder")
    }
}
