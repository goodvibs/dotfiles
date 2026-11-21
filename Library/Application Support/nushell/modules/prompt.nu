# modules/prompt.nu
#
# A Nushell port of the Powerlevel10k "pure" prompt configured in ~/.p10k.zsh:
#
#   [user@host] dir git-status [duration] MODE ❯          12:34:56 PM
#
# Left prompt segments, in the same order as POWERLEVEL9K_LEFT_PROMPT_ELEMENTS:
#   context (only for SSH or root), dir, vcs, command_execution_time (>= 5s),
#   helix_mode badge, prompt_char.
#
# Wiring (see config.nu):
#   PROMPT_COMMAND      -> `prompt left`   (context, dir, git, duration)
#   PROMPT_INDICATOR_*  -> `prompt indicator <mode>` (mode badge + prompt char)
#   PROMPT_COMMAND_RIGHT -> `prompt right` (clock)
#   TRANSIENT_PROMPT_*  -> only the prompt char survives after a command runs
#
# Notes:
# - Reedline picks PROMPT_INDICATOR_VI_INSERT in Helix insert mode and
#   PROMPT_INDICATOR_VI_NORMAL in Helix normal AND select mode, so the badge can
#   say INSERT or NORMAL but cannot distinguish SELECT (the cursor shape can).
# - Nushell prompts are synchronous (p10k's git status is async). Set
#   `$env.NU_PROMPT_GIT = '0'` to disable the git segment, e.g. in a huge repo.

const grey = '#6c6c6c'     # p10k color 242
const red = '#FF5C57'
const yellow = '#F3F99D'
const blue = '#57C7FF'
const magenta = '#FF6AC1'
const cyan = '#9AEDFE'
const white = '#F1F1F0'
const insert_green = '#9ece6a'   # tokyonight statusline, as in POWERLEVEL9K_HELIX_MODE_*
const normal_blue = '#7aa2f7'

def paint [color: string, text: string]: nothing -> string {
    $"(ansi --escape {fg: $color})($text)(ansi reset)"
}

# user@host, shown only for root or SSH sessions (as in the p10k config).
def context-segment []: nothing -> string {
    let in_ssh = (
        ($env.SSH_CONNECTION? | default '') != ''
        or ($env.SSH_CLIENT? | default '') != ''
        or ($env.SSH_TTY? | default '') != ''
    )
    let user = ($env.USER? | default 'user')

    if (is-admin) or $in_ssh {
        let host = (try { ^hostname -s | str trim } catch { 'host' })
        if (is-admin) {
            $"(paint $white $user)(paint $grey $'@($host)')"
        } else {
            paint $grey $'($user)@($host)'
        }
    } else {
        ''
    }
}

# Current directory in blue, with $HOME abbreviated to ~ (p10k does not shorten it).
def dir-segment []: nothing -> string {
    let pwd = $env.PWD
    let home = $nu.home-dir
    let shown = if $pwd == $home {
        '~'
    } else if ($pwd | str starts-with $'($home)/') {
        $'~($pwd | str substring ($home | str length)..)'
    } else {
        $pwd
    }
    paint $blue $shown
}

# Git status in grey: `branch*` (or `@sha` when detached), `*` when anything is
# staged, unstaged or untracked, and cyan ⇣ / ⇡ when behind / ahead of upstream.
def git-segment []: nothing -> string {
    if ($env.NU_PROMPT_GIT? | default '1') == '0' {
        return ''
    }

    let res = (try {
        ^git --no-optional-locks status --porcelain=v2 --branch | complete
    } catch {
        {exit_code: 1, stdout: ''}
    })
    if $res.exit_code != 0 {
        return ''
    }

    let lines = ($res.stdout | lines)
    let meta = (
        $lines
        | where {|l| $l | str starts-with '# ' }
        | each {|l| $l | str substring 2.. | split row ' ' }
        | reduce --fold {} {|it, acc| $acc | merge {($it | first): ($it | skip 1)} }
    )

    let head = ($meta | get -o 'branch.head' | default ['(unknown)'] | first)
    let name = if $head == '(detached)' {
        let oid = ($meta | get -o 'branch.oid' | default [''] | first)
        $'@($oid | str substring 0..<8)'
    } else {
        $head
    }

    let dirty = (
        $lines
        | where {|l| $l != '' and not ($l | str starts-with '# ') }
        | is-not-empty
    )

    let ab = ($meta | get -o 'branch.ab' | default ['+0' '-0'])
    let ahead = ($ab | get 0 | str substring 1.. | into int)
    let behind = ($ab | get 1 | str substring 1.. | into int)
    let arrows = $"(if $behind > 0 { '⇣' } else { '' })(if $ahead > 0 { '⇡' } else { '' })"

    let branch_text = paint $grey $"($name)(if $dirty { '*' } else { '' })"
    if $arrows == '' {
        $branch_text
    } else {
        $"($branch_text) (paint $cyan $arrows)"
    }
}

# Previous command duration (yellow), only when >= 5s, formatted like `1d 2h 3m 4s`
# with leading zero units dropped and no fractional seconds.
def duration-segment []: nothing -> string {
    let ms = ($env.CMD_DURATION_MS? | default '0' | into int)
    if $ms < 5000 {
        return ''
    }

    let total = ($ms // 1000)
    let d = ($total // 86400)
    let h = (($total mod 86400) // 3600)
    let m = (($total mod 3600) // 60)
    let s = ($total mod 60)

    let text = if $d > 0 {
        $'($d)d ($h)h ($m)m ($s)s'
    } else if $h > 0 {
        $'($h)h ($m)m ($s)s'
    } else if $m > 0 {
        $'($m)m ($s)s'
    } else {
        $'($s)s'
    }
    paint $yellow $text
}

def prompt-char [glyph: string]: nothing -> string {
    let failed = (($env.LAST_EXIT_CODE? | default 0) != 0)
    paint (if $failed { $red } else { $magenta }) $glyph
}

# The left prompt: everything before the mode badge and prompt char.
export def left []: nothing -> string {
    [
        (context-segment)
        (dir-segment)
        (git-segment)
        (duration-segment)
    ]
    | where {|s| $s != '' }
    | str join ' '
}

# The grey 12-hour clock, as in POWERLEVEL9K_TIME_FORMAT.
export def right []: nothing -> string {
    paint $grey (date now | format date '%I:%M:%S %p')
}

# Mode badge plus prompt char; appended by reedline after `prompt left`.
#   insert -> ` INSERT ❯ `   normal -> ` NORMAL ❮ `
export def indicator [mode: string]: nothing -> string {
    match $mode {
        'normal' => $" (paint $normal_blue 'NORMAL') (prompt-char '❮') "
        _ => $" (paint $insert_green 'INSERT') (prompt-char '❯') "
    }
}

# What remains of the prompt after a command is accepted (transient prompt).
export def transient-indicator []: nothing -> string {
    $"(prompt-char '❯') "
}

# Continuation prompt for multi-line input.
export def multiline []: nothing -> string {
    $"(paint $grey '…') "
}
