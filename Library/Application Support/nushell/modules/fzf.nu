# modules/fzf.nu
#
# Nushell versions of the shell widgets that `fzf --zsh` and ~/.zshrc provide:
#
#   Ctrl+T   fzf-path     pick files/dirs with fd + fzf and insert them at the cursor
#   Alt+C    fzf-cd       pick a directory with fd + fzf and cd into it
#   Ctrl+R   fzf-history  fuzzy-search history and replace the commandline
#   Ctrl+Space project-cd pick a project with project-picker and cd into it
#
# They are bound to keys in config.nu through `executehostcommand`, which runs
# the command in the live REPL (so `cd` sticks) without adding it to history.
# The fd commands come from $env.FZF_CTRL_T_COMMAND / $env.FZF_ALT_C_COMMAND,
# set in env.nu to the same values as ~/.zshrc.

const fzf_base = [--height=40% --layout=reverse --scheme=path]

# Quote a path for insertion into a Nushell commandline, if it needs it.
def quote-path [p: string]: nothing -> string {
    if ($p =~ '[\s\(\)\[\]\{\}\$;|&<>`"'']') {
        if ($p | str contains "'") {
            let escaped = ($p | str replace --all '\' '\\' | str replace --all '"' '\"')
            $'"($escaped)"'
        } else {
            $"'($p)'"
        }
    } else {
        $p
    }
}

# Run `sh -c <command> | fzf <args>` and return the trimmed selection ('' if cancelled).
def pick [command: string, args: list<string>]: nothing -> string {
    do --ignore-errors { ^sh -c $command | ^fzf ...$args }
    | default ''
    | str trim
}

# Ctrl+T: files and directories, multi-select, quoted for Nushell.
export def fzf-path []: nothing -> string {
    let command = ($env.FZF_CTRL_T_COMMAND? | default 'fd --strip-cwd-prefix --hidden --follow --exclude .git')
    let picked = (pick $command ($fzf_base ++ [--multi]))
    if $picked == '' {
        return ''
    }
    $"($picked | lines | where {|l| $l != '' } | each {|l| quote-path $l } | str join ' ') "
}

# Alt+C: directories only.
export def --env fzf-cd []: nothing -> nothing {
    let command = ($env.FZF_ALT_C_COMMAND? | default 'fd --type d --strip-cwd-prefix --hidden --follow --exclude .git')
    let picked = (pick $command $fzf_base)
    if $picked != '' {
        cd $picked
    }
}

# Ctrl+R: history search seeded with the current commandline. Entries are
# NUL-separated so multi-line commands survive intact.
export def fzf-history []: nothing -> string {
    let query = (commandline)
    let entries = (history | get command | reverse | uniq | str join (char nul))
    do --ignore-errors {
        $entries | ^fzf --read0 --print0 --height=40% --layout=reverse --scheme=history --tiebreak=index --query $query
    }
    | default ''
    | str replace --all (char nul) ''
}

# Ctrl+Space: replaces zsh's `project-widget`.
export def --env project-cd []: nothing -> nothing {
    let project = (do --ignore-errors { ^project-picker } | default '' | str trim)
    if $project != '' {
        cd $project
    }
}
