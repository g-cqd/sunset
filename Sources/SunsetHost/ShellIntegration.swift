import Foundation

/// Teaches the shell to mark its prompts (OSC 133: where a prompt starts, where a command's output starts, how it ended), so that the window can go from
/// one prompt to the next, without the user's files being touched. Only zsh for now. zsh reads its start files from `$ZDOTDIR`: it is pointed at a
/// directory of ours whose `.zshenv` gives `ZDOTDIR` back as it was, reads the user's own `.zshenv`, and adds two hooks; every later file (`.zprofile`,
/// `.zshrc`) is then read from the user's directory as always.
public enum ShellIntegration {
    /// What to add to the environment of `command` (its executable first) so that its shell marks its prompts; empty for a program that is not taught.
    /// The files are written under `directory` when they are not there as they should be.
    public static func environment(for command: [String], inherited: [String: String], directory: String) throws
        -> [String: String]
    {
        guard let executable = command.first else { return [:] }
        var name = Substring(executable.split(separator: "/").last ?? "")
        if name.hasPrefix("-") { name = name.dropFirst() }
        guard name == "zsh" else { return [:] }
        let home = directory + "/zsh"
        let file = home + "/.zshenv"
        if (try? String(contentsOfFile: file, encoding: .utf8)) != zsh {
            try FileManager.default.createDirectory(atPath: home, withIntermediateDirectories: true)
            try zsh.write(toFile: file, atomically: true, encoding: .utf8)
        }
        var added = ["ZDOTDIR": home]
        if let own = inherited["ZDOTDIR"] { added["SUNSET_ZDOTDIR"] = own }
        return added
    }

    /// The `.zshenv` zsh reads instead of the user's, first.
    static let zsh = #"""
        # Written by Sunset at each start; changes here are lost. Turn it off with terminal.shellIntegration in Sunset's settings.
        if [[ -n "${SUNSET_ZDOTDIR+set}" ]]; then
            ZDOTDIR="$SUNSET_ZDOTDIR"
            builtin unset SUNSET_ZDOTDIR
        else
            builtin unset ZDOTDIR
        fi
        if [[ -r "${ZDOTDIR:-$HOME}/.zshenv" ]]; then
            builtin source "${ZDOTDIR:-$HOME}/.zshenv"
        fi
        if [[ -o interactive && -z "${_sunset_ran+set}" ]]; then
            builtin typeset -g _sunset_ran=
            _sunset_precmd() {
                builtin local code=$?
                [[ -n "$_sunset_ran" ]] && builtin print -n "\e]133;D;${code}\a"
                _sunset_ran=
                builtin print -n "\e]133;A\a"
            }
            _sunset_preexec() {
                _sunset_ran=1
                builtin print -n "\e]133;C\a"
            }
            builtin autoload -Uz add-zsh-hook
            add-zsh-hook precmd _sunset_precmd
            add-zsh-hook preexec _sunset_preexec
        fi

        """#
}
