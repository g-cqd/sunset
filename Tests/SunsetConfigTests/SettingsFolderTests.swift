import Testing

@testable import SunsetConfig

/// Every setting that holds a folder says so; what is chosen is written as the file writes it, under the home folder
/// with `~`.
@Suite("Settings that hold a folder") struct SettingsFolderTests {
    @Test func `the download folder and the terminal's starting directory hold a folder, in monospace`() {
        let folders = SettingsOption.all.filter(\.isFolder).map(\.id).sorted()
        #expect(folders == ["terminal.directory", "web.downloadFolder"])
        #expect(SettingsOption.all.filter(\.isFolder).allSatisfy { $0.isCode })
    }

    @Test func `a folder chosen is written with ~ under the home folder, else as it is`() {
        #expect(SettingsOption.written(folder: "/Users/a/Downloads/", home: "/Users/a") == "~/Downloads")
        #expect(SettingsOption.written(folder: "/Users/a", home: "/Users/a") == "~")
        #expect(SettingsOption.written(folder: "/Users/ab/x", home: "/Users/a") == "/Users/ab/x")
        #expect(SettingsOption.written(folder: "/Volumes/Disk/In", home: "/Users/a") == "/Volumes/Disk/In")
    }
}
