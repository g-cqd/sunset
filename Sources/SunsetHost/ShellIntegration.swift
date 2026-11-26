import Foundation

/// Teaches the shell to mark its prompts (OSC 133: where a prompt starts, where a command's output starts, how it ended)
/// and report its working directory (OSC 7 `file://host/path`), without touching the user's own shell dotfiles (T-2 / t186).
///
/// - **zsh:** pointed via `ZDOTDIR` at a Sunset-managed directory whose `.zshenv` restores `ZDOTDIR`, sources the user's
///   `.zshenv`, and installs `precmd`/`preexec` hooks (emitting OSC 133 + OSC 7).
/// - **bash:** started via `prepare(command:inherited:directory:)` with `--rcfile` sourcing the user's login/interactive
///   startup files and installing `PROMPT_COMMAND` + `DEBUG` trap hooks for OSC 133 + OSC 7.
/// - **fish (4+):** emits OSC 133 and OSC 7 natively, so nothing is injected.
public enum ShellIntegration {
    /// Result of preparing a shell launch: possibly adjusted `command` (e.g. bash `--rcfile`) and extra `environment`.
    public struct Prepared: Sendable, Equatable {
        public let command: [String]
        public let environment: [String: String]

        public init(command: [String], environment: [String: String]) {
            self.command = command
            self.environment = environment
        }
    }

    /// Prepares both command arguments and environment for `command`. Leaves non-integrated shells unchanged.
    public static func prepare(
        command: [String],
        inherited: [String: String],
        directory: String
    ) throws -> Prepared {
        guard let executable = command.first else { return Prepared(command: command, environment: [:]) }
        switch shellName(of: executable) {
            case "zsh":
                let home = try ensureScript(zsh, subfolder: "zsh", filename: ".zshenv", under: directory)
                var added = ["ZDOTDIR": home]
                if let own = inherited["ZDOTDIR"] { added["SUNSET_ZDOTDIR"] = own }
                return Prepared(command: command, environment: added)
            case "bash":
                return try installBash(command: command, inherited: inherited, directory: directory)
            default:
                return Prepared(command: command, environment: [:])
        }
    }

    /// Backward-compatible environment-only helper (zsh and bash environment variables).
    public static func environment(for command: [String], inherited: [String: String], directory: String) throws
        -> [String: String]
    {
        try prepare(command: command, inherited: inherited, directory: directory).environment
    }

    private static func shellName(of executable: String) -> Substring {
        var name = Substring(executable.split(separator: "/").last ?? "")
        if name.hasPrefix("-") { name = name.dropFirst() }
        return name
    }

    private static func ensureScript(
        _ content: String,
        subfolder: String,
        filename: String,
        under directory: String
    ) throws -> String {
        let home = "\(directory)/\(subfolder)"
        let file = "\(home)/\(filename)"
        if (try? String(contentsOfFile: file, encoding: .utf8)) != content {
            try FileManager.default.createDirectory(atPath: home, withIntermediateDirectories: true)
            try content.write(toFile: file, atomically: true, encoding: .utf8)
        }
        return home
    }

    private static func installBash(
        command: [String],
        inherited: [String: String],
        directory: String
    ) throws -> Prepared {
        let args = command.dropFirst()
        let blocked: Set<String> = ["-c", "--norc", "--noprofile", "--rcfile", "--init-file"]
        guard !args.contains(where: blocked.contains) else { return Prepared(command: command, environment: [:]) }
        let home = try ensureScript(bash, subfolder: "bash", filename: "sunset.bashrc", under: directory)
        let isLogin = command[0].hasPrefix("-") || args.contains("-l") || args.contains("--login")
        let filteredArgs = args.filter { $0 != "-l" && $0 != "--login" }
        var launched = [command[0], "--rcfile", "\(home)/sunset.bashrc"]
        launched.append(contentsOf: filteredArgs)
        var added: [String: String] = ["SUNSET_BASH_LOGIN": isLogin ? "1" : "0"]
        if let existing = inherited["ENV"] { added["SUNSET_BASH_ENV"] = existing }
        return Prepared(command: launched, environment: added)
    }

    /// The `.zshenv` zsh reads instead of the user's, first. Reports OSC 133 prompt marks and OSC 7 working directory.
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
            _sunset_osc7() {
                builtin local host="${HOST:-localhost}" pwd_path="$PWD" encoded="" i ch hex
                for (( i = 1; i <= ${#pwd_path}; i++ )); do
                    ch="${pwd_path[$i]}"
                    case "$ch" in
                        [a-zA-Z0-9/._~-]) encoded+="$ch" ;;
                        *) printf -v hex '%%%02X' "'$ch"; encoded+="$hex" ;;
                    esac
                done
                builtin print -n "\e]7;file://${host}${encoded}\a"
            }
            _sunset_precmd() {
                builtin local code=$?
                [[ -n "$_sunset_ran" ]] && builtin print -n "\e]133;D;${code}\a"
                _sunset_ran=
                _sunset_osc7
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

    /// The rcfile bash reads at start: sources the user's own login/interactive startup files, then hooks PROMPT_COMMAND
    /// and the DEBUG trap to emit OSC 133 prompt marks and OSC 7 working directory reports.
    static var bash: String {
        bashPreamble + bashHooks
    }

    private static let bashPreamble = #"""
        # Written by Sunset at each start; changes here are lost. Turn it off with terminal.shellIntegration in Sunset's settings.
        if [[ "${SUNSET_BASH_LOGIN:-0}" == "1" ]]; then
            [[ -r /etc/profile ]] && source /etc/profile
            if [[ -r "$HOME/.bash_profile" ]]; then source "$HOME/.bash_profile"
            elif [[ -r "$HOME/.bash_login" ]]; then source "$HOME/.bash_login"
            elif [[ -r "$HOME/.profile" ]]; then source "$HOME/.profile"
            fi
        else
            [[ -r "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
        fi
        unset SUNSET_BASH_LOGIN

        """#

    private static let bashHooks = #"""
        if [[ $- == *i* && -z "${_sunset_bash_installed+set}" ]]; then
            _sunset_bash_installed=1
            _sunset_ran=""
            _sunset_in_prompt=1
            _sunset_osc7() {
                local host="${HOSTNAME:-localhost}" pwd_path="$PWD" encoded="" i ch hex
                for (( i = 0; i < ${#pwd_path}; i++ )); do
                    ch="${pwd_path:i:1}"
                    case "$ch" in
                        [a-zA-Z0-9/._~-]) encoded+="$ch" ;;
                        *) printf -v hex '%%%02X' "'$ch"; encoded+="$hex" ;;
                    esac
                done
                printf '\e]7;file://%s%s\a' "$host" "$encoded"
            }
            _sunset_precmd() {
                local code=$?
                [[ -n "$_sunset_ran" ]] && printf '\e]133;D;%d\a' "$code"
                _sunset_ran=""
                _sunset_osc7
                printf '\e]133;A\a'
                _sunset_in_prompt=0
            }
            _sunset_preexec() {
                if [[ "$_sunset_in_prompt" == "0" && "$BASH_COMMAND" != "_sunset_precmd"* ]]; then
                    _sunset_in_prompt=1
                    _sunset_ran=1
                    printf '\e]133;C\a'
                fi
            }
            PROMPT_COMMAND="_sunset_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
            trap '_sunset_preexec' DEBUG
        fi

        """#
}
