/// The scripts the taught shells read (T-2 / t186): zsh's `.zshenv` and bash's rcfile, each made of its own parts and
/// one directory report shared by both (`osc7`), so the two shells encode a directory the same way.
extension ShellIntegration {
    /// The `.zshenv` zsh reads instead of the user's, first. Reports OSC 133 prompt marks and OSC 7 working directory.
    static let zsh = zshHead + osc7(setup: "    builtin emulate -L zsh\n    builtin setopt no_multibyte\n") + zshHooks

    /// The rcfile bash reads at start: sources the user's own startup files, then adds its prompt commands and (when the
    /// user has none) its DEBUG trap around theirs, for OSC 133 prompt marks and OSC 7 working directory reports.
    static var bash: String {
        bashPreamble + bashHead + osc7(setup: "    local LC_ALL=C\n") + bashHooks
    }

    /// `_sunset_osc7`: the directory as OSC 7 carries it, each byte of its UTF-8 that is not unreserved percent-encoded.
    /// `setup` makes the shell see bytes, not characters (zsh: `no_multibyte`; bash: `LC_ALL=C`); a byte's value is
    /// masked, as bash 3.2 reads a byte above 0x7f as negative. `${p:$i:1}`, `[!…]` and `printf -v` mean the same in
    /// both shells (zsh would read `${p:i:1}` as a history modifier, hence `$i`).
    private static func osc7(setup: String) -> String {
        "_sunset_osc7() {\n" + setup + osc7Body
    }

    private static let osc7Body = #"""
            local host="${HOSTNAME:-${HOST:-localhost}}" pwd_path="$PWD" encoded="" i ch n hex
            if [[ "$pwd_path" == *[!a-zA-Z0-9/._~-]* ]]; then
                for (( i = 0; i < ${#pwd_path}; i++ )); do
                    ch="${pwd_path:$i:1}"
                    case "$ch" in
                        [a-zA-Z0-9/._~-]) encoded+="$ch" ;;
                        *) builtin printf -v n '%d' "'$ch"; builtin printf -v hex '%%%02X' $(( n & 255 )); encoded+="$hex" ;;
                    esac
                done
            else
                encoded="$pwd_path"
            fi
            builtin printf '\e]7;file://%s%s\a' "$host" "$encoded"
        }

        """#

    private static let zshHead = #"""
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

        """#

    private static let zshHooks = #"""
        if [[ -o interactive && -z "${_sunset_ran+set}" ]]; then
            builtin typeset -g _sunset_ran=
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

    /// bash's marks need the shell to be interactive, and are added once.
    private static let bashHead = #"""
        [[ $- == *i* && -z "${_sunset_bash_installed+set}" ]] || return 0
        _sunset_bash_installed=1
        _sunset_ran=""
        _sunset_armed=""

        """#

    private static let bashHooks = #"""
        # A prompt: the last command's end (and status) when one ran, the directory, the prompt's start. It runs first of
        # the prompt commands and hands their $? on.
        _sunset_precmd() {
            local code=$?
            _sunset_armed=""
            [[ -n "$_sunset_ran" ]] && printf '\e]133;D;%d\a' "$code"
            _sunset_ran=""
            _sunset_osc7
            printf '\e]133;A\a'
            return $code
        }
        # Last of the prompt commands: what runs next is a command the user typed.
        _sunset_arm() {
            local code=$?
            _sunset_armed=1
            return $code
        }
        # The DEBUG trap, before each simple command: the first one after the prompt, if it is not the prompt's own, is
        # the user's, and its output starts here. An empty line runs nothing, so marks nothing.
        _sunset_preexec() {
            if [[ "$BASH_COMMAND" == _sunset_precmd* ]]; then
                _sunset_armed=""
            elif [[ -n "$_sunset_armed" ]]; then
                _sunset_armed=""
                _sunset_ran=1
                printf '\e]133;C\a'
            fi
        }
        # Around the user's prompt commands, never in their place. An array stays one where bash runs it whole (5.1 and
        # later); before that bash runs only its first element, which is the string the else branch extends.
        if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )) \
            && [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
            PROMPT_COMMAND=(_sunset_precmd "${PROMPT_COMMAND[@]}" _sunset_arm)
        else
            PROMPT_COMMAND="_sunset_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}; _sunset_arm"
        fi
        # Only when the user has no DEBUG trap of their own: theirs is kept, and then where a command's output starts and
        # how it ended are not marked; prompts and the directory still are.
        if [[ -z "$(trap -p DEBUG)" ]]; then
            trap '_sunset_preexec' DEBUG
        fi

        """#
}
