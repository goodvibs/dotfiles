# config.nu
#
# Nushell configuration, set up to feel like the zsh setup in ~/.zshrc:
# Helix editing mode, a p10k-pure-style prompt, fzf widgets, zoxide and fnm.
#
# Layout (all in this directory):
#   env.nu               PATH, EDITOR, FZF_*, cert variables
#   config.nu            this file: settings, colors, keybindings, hooks, aliases
#   modules/prompt.nu    the prompt (port of ~/.p10k.zsh)
#   modules/fzf.nu       fzf / project-picker widgets
#   autoload/*.nu        sourced automatically after this file (work.nu comes
#                        from the private yadm repo, see ~/.config/yadm/README.md)
#   vendor/autoload/     generated and untracked, e.g. zoxide.nu (see
#                        ~/.config/yadm/plugins/install-scripts/nushell.sh)
#
# Reload after editing with `exec nu`. Start without any config: `nu -n`.
# Docs: `config nu --doc | nu-highlight | less -R`

use modules/prompt.nu
use modules/fzf.nu *

# --- General -----------------------------------------------------------------

$env.config.show_banner = false
$env.config.buffer_editor = 'hx'

# --- Helix mode ----------------------------------------------------------------
#
# Reedline's built-in Helix mode. Multi-cursor is not implemented upstream yet;
# Ctrl+O (or Alt+E below) opens the commandline in Helix for that.

$env.config.edit_mode = 'helix'

# Same shapes as zsh-helix-mode: blinking bar in insert, block otherwise.
$env.config.cursor_shape.helix_insert = 'blink_line'
$env.config.cursor_shape.helix_normal = 'block'
$env.config.cursor_shape.helix_select = 'block'

# --- Colors (TokyoNight Night, matching Ghostty and Helix) -----------------------

$env.config.color_config = ($env.config.color_config | merge {
    hints: '#565f89'
    separator: '#565f89'
    header: {fg: '#9ece6a' attr: b}
    row_index: {fg: '#bb9af7' attr: b}
    leading_trailing_space_bg: {bg: '#3b4261'}
    selection: {bg: '#33467c'}
    selection_cursor: {fg: '#1a1b26' bg: '#7aa2f7'}
    status_line_error: '#f7768e'

    shape_external: '#7aa2f7'
    shape_external_resolved: '#7aa2f7'
    shape_externalarg: '#9ece6a'
    shape_internalcall: {fg: '#7aa2f7' attr: b}
    shape_keyword: '#bb9af7'
    shape_vardecl: '#bb9af7'
    shape_variable: '#bb9af7'
    shape_flag: '#e0af68'
    shape_operator: '#e0af68'
    shape_range: '#e0af68'
    shape_pipe: '#bb9af7'
    shape_redirection: '#bb9af7'
    shape_string: '#9ece6a'
    shape_string_interpolation: '#73daca'
    shape_raw_string: '#9ece6a'
    shape_int: '#ff9e64'
    shape_float: '#ff9e64'
    shape_bool: '#ff9e64'
    shape_nothing: '#ff9e64'
    shape_datetime: '#7dcfff'
    shape_filepath: '#7dcfff'
    shape_directory: '#7dcfff'
    shape_globpattern: '#7dcfff'
    shape_glob_interpolation: '#7dcfff'
    shape_record: '#7dcfff'
    shape_list: '#7dcfff'
    shape_table: '#7dcfff'
    shape_closure: '#7dcfff'
    shape_block: '#7dcfff'
    shape_signature: '#9ece6a'
    shape_literal: '#7aa2f7'
    shape_custom: '#9ece6a'
    shape_matching_brackets: {attr: u}
    shape_garbage: {fg: '#c0caf5' bg: '#f7768e'}
})

# --- Prompt (see modules/prompt.nu) ----------------------------------------------

$env.PROMPT_COMMAND = {|| prompt left }
$env.PROMPT_COMMAND_RIGHT = {|| prompt right }

# Helix insert uses the VI_INSERT indicator; Helix normal and select both use
# VI_NORMAL. Emacs mode (if ever selected) falls back to the insert look.
$env.PROMPT_INDICATOR = {|| prompt indicator insert }
$env.PROMPT_INDICATOR_VI_INSERT = {|| prompt indicator insert }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| prompt indicator normal }
$env.PROMPT_MULTILINE_INDICATOR = {|| prompt multiline }

# Transient prompt: after a command runs, only the prompt char is left behind.
$env.TRANSIENT_PROMPT_COMMAND = ''
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ''
$env.TRANSIENT_PROMPT_INDICATOR = {|| prompt transient-indicator }
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| prompt transient-indicator }
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| prompt transient-indicator }
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ''

# --- Keybindings -------------------------------------------------------------------
#
# `executehostcommand` runs in the live REPL without touching history, so `cd`
# sticks and nothing is echoed. Reedline has no key chords, so zsh's
# Ctrl+X Ctrl+E is Alt+E here (Ctrl+O also works out of the box).

let all_modes = [emacs helix_insert helix_normal helix_select]

$env.config.keybindings ++= [
    {
        name: fzf_insert_path
        modifier: control
        keycode: char_t
        mode: $all_modes
        event: {send: executehostcommand cmd: 'commandline edit --insert (fzf-path)'}
    }
    {
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: $all_modes
        event: {send: executehostcommand cmd: 'fzf-cd'}
    }
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: $all_modes
        event: {send: executehostcommand cmd: 'commandline edit --replace (fzf-history)'}
    }
    {
        name: project_picker
        modifier: control
        keycode: space
        mode: $all_modes
        event: {send: executehostcommand cmd: 'project-cd'}
    }
    {
        name: edit_in_helix
        modifier: alt
        keycode: char_e
        mode: $all_modes
        event: {send: OpenEditor}
    }
]

# --- Node (fnm) ----------------------------------------------------------------------
#
# fnm has no Nushell shell mode. From a zsh parent the environment (including
# the multishell PATH entry) is inherited; otherwise set it up from `--json`.
# Then mimic `--use-on-cd`.

if (which fnm | is-not-empty) {
    if ($env.FNM_MULTISHELL_PATH? | is-empty) {
        load-env (^fnm env --json | from json)
        $env.PATH = ($env.PATH | prepend $'($env.FNM_MULTISHELL_PATH)/bin')
    }

    $env.config.hooks.env_change.PWD = (
        $env.config.hooks.env_change.PWD?
        | default []
        | append {|before, after|
            let has_version_file = (
                ['.node-version' '.nvmrc' 'package.json']
                | any {|f| $after | path join $f | path exists }
            )
            if $has_version_file {
                try { ^fnm use --silent-if-unchanged --log-level=quiet }
            }
        }
    )
}

# --- Aliases and helpers ----------------------------------------------------------------

alias lg = lazygit
alias e = ls --all

# Open this config in Helix; apply changes with `exec nu`.
def nu-config-open [] {
    ^hx $nu.default-config-dir
}
