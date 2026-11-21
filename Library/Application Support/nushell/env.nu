# env.nu
#
# Environment for Nushell. Mirrors ~/.zshenv and the exports in ~/.zshrc so that
# `nu` behaves the same whether it is launched from zsh (environment inherited)
# or directly (e.g. a Ghostty tab running `nu`).
#
# Work-only environment lives in autoload/ (yadm-private): work.nu and zscaler.nu.

let home = $env.HOME
let brew = '/opt/homebrew'

$env.HOMEBREW_PREFIX = $brew

# PATH: same order as ~/.zshrc, then whatever was inherited. Entries that do not
# exist are dropped, and duplicates are removed (first occurrence wins).
let preferred = [
    ($env.REX_BIN_DIR? | default '')
    $'($home)/.local/bin'
    $'($home)/.local/share/dotfiles/plugins/bin'
    $'($brew)/opt/rustup/bin'
    $'($home)/.cargo/bin'
    $'($home)/.lmstudio/bin'
    '/Applications/Ghostty.app/Contents/MacOS'
    $'($brew)/bin'
    $'($brew)/sbin'
    $'($brew)/opt/openjdk/bin'
    $'($brew)/opt/llvm'
    '/usr/local/bin'
    '/usr/bin'
    '/bin'
    '/usr/sbin'
    '/sbin'
]

# An fnm multishell dir inherited from a parent zsh must stay first, or Homebrew's
# node would shadow the fnm-selected one.
let inherited = ($env.PATH | default [])
let fnm_shims = ($inherited | where {|p| $p | str contains 'fnm_multishells' })

$env.PATH = (
    $fnm_shims ++ $preferred ++ $inherited
    | where {|p| $p != '' }
    | uniq
    | where {|p| $p | path exists }
)

$env.EDITOR = 'hx'
$env.JAVA_HOME = $'($brew)/opt/openjdk/libexec/openjdk.jdk/Contents/Home'

# fzf, same commands as ~/.zshrc.
$env.FZF_DEFAULT_COMMAND = 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
$env.FZF_CTRL_T_COMMAND = 'fd --strip-cwd-prefix --hidden --follow --exclude .git'
$env.FZF_ALT_C_COMMAND = 'fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
