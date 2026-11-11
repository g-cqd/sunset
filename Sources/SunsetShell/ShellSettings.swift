/// What the shell's views draw with: the same groups and names as Sunset's configuration file (`sidebar.*`, `layout.*`, `tabs.bar.*`), as plain values
/// (R8). The library does not read the file: the app fills this from its configuration (`SunsetShellBridge`), so a setting's name means the same thing
/// in the file, in Settings and here.
package struct ShellSettings: Sendable, Equatable {
    package var sidebar = Sidebar()
    package var layout = Layout()
    package var tabs = Tabs()

    package init() {}
}
