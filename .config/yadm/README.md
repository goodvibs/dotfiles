# Dotfiles

Managed with [yadm](https://yadm.io). Files live in `$HOME` as real files; there
is no symlink farm. Only paths added with `yadm add` are tracked, so app-generated
files next to a config are ignored.

## New machine

```bash
brew install yadm
yadm clone --bootstrap git@github.com:goodvibs/dotfiles.git
```

`~/.config/yadm/bootstrap` then updates the nvim and helix submodules, runs
`brew bundle --global` (reads `~/.Brewfile`), and runs the plugin install scripts.
Re-run it any time with `yadm bootstrap`.

Skip parts with `DOTFILES_SKIP_BREW=1` or `DOTFILES_SKIP_PLUGINS=1`.

## Work-specific files (private repo)

Work-only config is kept in a second, private yadm instance, `yadm-private`
(`~/.local/bin/yadm-private`), with its own repo under
`~/.local/share/yadm-private`. It tracks three files as `##class.Work`
alternates: `~/.zshrc.local`, `~/.cargo/config.local.toml`, and
`~/.config/git/config-work`. The public configs only reference them
optionally (`source` if present, cargo `include` with `optional = true`, git
`includeIf`), so machines without the private repo work unchanged.

On a work machine, after the public clone:

```bash
DOTFILES_PRIVATE_URL=git@github.com:goodvibs/dotfiles-private.git yadm bootstrap
```

This clones the private repo, sets `local.class` to `Work` (override with
`DOTFILES_PRIVATE_CLASS`) in the private instance only, and runs
`yadm-private alt` to create the links.

Never `yadm add` a work file. Use `yadm-private add`.

## Daily use

```bash
yadm status          # public repo
yadm add <file>
yadm commit -m "..."
yadm push

yadm-private status  # private repo
```

`yadm status` hides untracked files on purpose. Do not run `yadm add .`,
`yadm clean`, or `yadm stash -u`: the work tree is all of `$HOME`.

## Layout notes

- `~/.config/nvim` and `~/.config/helix` are submodules
  (`goodvibs/nvim-config`, `goodvibs/hx-config`). Commit inside them, push, then
  commit the updated pointer with `yadm`.
- `~/.claude/CLAUDE.md` is a relative symlink to `~/.config/agents/AGENTS.md`.
- `~/.config/rex/scripts/project-{picker,filter}` are symlinks into `~/.local/bin`.
- Plugin install scripts and `zsh-helix-mode.zsh` live in
  `~/.config/yadm/plugins/`. Their output goes to
  `~/.local/share/dotfiles/plugins/bin` (untracked, on `PATH`).
- `~/.cursor` is a symlink to `~/.config/cursor`, so Cursor files are tracked
  under `.config/cursor/`.
