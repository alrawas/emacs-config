# ARAWAS GNU Emacs Config

A plain `init.el`, built-ins first, evil kept. One config for Emacs 29 and
30, in a window or in a terminal (`emacs -nw`), on the laptop and over SSH.

## Layout

| File | What it holds |
|---|---|
| `early-init.el` | Runs first: garbage-collection threshold, frame look (font, transparency, no bars; terminals ignore it), two evil settings that must exist before evil loads |
| `init.el` | Everything else, top to bottom, one `use-package` block per package. TAB on a `;;;` line folds that section |
| `lisp/` | My own commands: org notes (`my-org-notes.el`), todo.txt helpers (`my-todotxt.el`), `which-keymap.el` |
| `themes/` | Single-file themes (gruber-darker is the one in use) |

## Install

```bash
git clone git@github.com:alrawas/emacs-config.git ~/.config/emacs
emacs        # or emacs -nw
```

The first launch downloads the packages (about a minute). Later starts take
under a second.

## Packages

Everything downloaded is one list, `package-selected-packages`, under
`;;; Packages` in `init.el`. Anything not listed ships with Emacs.

- **Add:** put the name in the list, restart.
- **Remove:** delete it from the list, `M-x package-autoremove`.
- **Update:** `M-x package-upgrade-all`.

`custom.el` is never loaded, so `init.el` is the only place settings live.

## Language servers (install on each machine)

Eglot (built in) talks to them; nothing else to configure.

- **Go:** `go install golang.org/x/tools/gopls@latest`
- **Java:** `jdtls` on PATH. It needs Java 21+ to run; projects can target older Java.
- **Search:** `rg` (ripgrep) for `SPC s r`

A GUI Emacs started from the desktop doesn't get the shell's PATH, so
`init.el` adds `~/.local/bin`, `~/go/bin`, `/usr/local/go/bin` and SDKMAN's
current java/maven/gradle itself.

## Terminal and SSH

- Copying in a terminal Emacs reaches your local clipboard (OSC 52). Inside
  tmux, add `set -g set-clipboard on` to `~/.tmux.conf`.
- If `emacs -nw` on a server says the terminal type is unknown:
  `infocmp -x alacritty | ssh HOST -- tic -x -` (once).

## Keys

`SPC` is the leader in normal/visual state, `M-SPC` everywhere else.
`which-key` lists what comes next after any prefix.

| Key | Does |
|---|---|
| `SPC SPC` | M-x |
| `SPC .` | find file |
| `SPC ,` | buffers, recent files, bookmarks in one list (`b␣` `f␣` `m␣` to narrow) |
| `SPC h` | help, same as `C-h` |
| `SPC p` | projects, same as `C-x p` (`p` switch, `f` file, `g` grep, `c` compile, `m` magit) |
| `SPC r` | bookmarks, same as `C-x r` (`m` set, `b` jump, `l` list) |
| `SPC w` | windows, same as `C-w` |
| `SPC x` | anything else under `C-x` |
| `SPC b` | buffers |
| `SPC c` | code: `a` actions, `r` rename, `f` format, `d` diagnostics |
| `SPC g` | git (magit) |
| `SPC s` | search: `s` line, `i` symbols, `r` project (ripgrep) |
| `SPC m` | org: `c` capture, `l` life.org, `w` write today |
| `SPC a` | todo.txt |
| `SPC e` | eval, eshell |
| `SPC d` | dired |
| `SPC t` | toggles |
