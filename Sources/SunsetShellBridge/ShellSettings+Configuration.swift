package import SunsetConfig
package import SunsetShell

extension ShellSettings {
    /// The shell's settings as the configuration file says them: every `sidebar.*`, `layout.*` and `tabs.bar.*` value, under the same name.
    package init(_ configuration: Configuration) {
        self.init()
        sidebar.enabled = configuration.sidebar.enabled
        sidebar.width = configuration.sidebar.width
        sidebar.padding = configuration.sidebar.padding
        sidebar.autoHide = configuration.sidebar.autoHide
        sidebar.side = configuration.sidebar.side == .left ? .left : .right
        tabs.bar.position = configuration.tabs.bar.position == .top ? .top : .bottom
        tabs.bar.showTitle = configuration.tabs.bar.showTitle
        tabs.bar.showIcon = configuration.tabs.bar.showIcon
        tabs.bar.showDirectory = configuration.tabs.bar.showDirectory
        tabs.bar.monospacedDirectory = configuration.tabs.bar.monospacedDirectory
        tabs.bar.showProgress = configuration.tabs.bar.showProgress
        layout = Layout(configuration.layout)
    }
}
