# nvim

My Neovim configuration. Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which installs itself and every plugin (pinned in `lazy-lock.json`) on first launch.

## Install

```sh
# Back up any existing config first
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
git clone https://github.com/Lomholy/nvim ~/.config/nvim
nvim
```

## Requirements

Required:

- Neovim 0.12.4+ (required by vimtex)
- `git`, `curl`, `tar`, and a C compiler with `make`

Optional (the config starts without them, but the matching feature is off):

| Tool | Used for |
| --- | --- |
| `tree-sitter` CLI (0.26.1+, not from npm) | Building Treesitter parsers for syntax highlighting |
| `ripgrep` | Telescope live grep (`<leader>fg`) |
| A [Nerd Font](https://www.nerdfonts.com) | Icons in lualine and nvim-tree |
| `node`/`npm` | Mason installing `eslint` |
| `python3` | Mason installing `ruff` |
| `mcstas-language-server` | McStas LSP (see [McStas](#mcstas)) |
| `prettier`, `isort`, `black` | Formatting with conform (`<leader>fo`) |
| `xclip` or `wl-clipboard` (Linux) | System clipboard |
| TeX distribution with `latexmk` | Compiling LaTeX (see [LaTeX](#latex)) |
| Skim (macOS) or Zathura (Linux) | Viewing the compiled PDF |

### macOS

```sh
xcode-select --install
brew install neovim tree-sitter-cli ripgrep node python pipx
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask basictex skim
sudo /Library/TeX/texbin/tlmgr update --self
sudo /Library/TeX/texbin/tlmgr install latexmk
```

### Debian/Ubuntu

The `neovim` package in apt is usually too old. Use the release tarball:

```sh
sudo apt install git curl tar build-essential ripgrep nodejs npm python3 pipx xclip
sudo apt install texlive-latex-extra latexmk zathura zathura-pdf-poppler xdotool
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
```

Get the `tree-sitter` CLI from its [releases page](https://github.com/tree-sitter/tree-sitter/releases), or run `cargo install --locked tree-sitter-cli`.

## LaTeX

[vimtex](https://github.com/lervag/vimtex) handles compiling and viewing:

- Opening any `.tex` file starts `latexmk` in continuous mode on the project's main file. Saving any file it includes rebuilds the PDF, and the viewer reloads it.
- vimtex finds the main file by itself. If it picks the wrong one, put `% !TEX root = main.tex` on the first line of the sub-file.
- `\ll` toggles compilation, `\lv` jumps to the cursor position in the PDF, `\le` shows errors, `\lt` opens the table of contents. See `:help vimtex-default-mappings`.
- The viewer is Skim on macOS, and Zathura on Linux (`zathura_simple` when `xdotool` is missing, e.g. on Wayland).
- macOS must allow your terminal to control Skim. If Skim never opens, run `osascript -l JavaScript -e 'Application("Skim").documents.length'` and accept the prompt. If it fails with error `-1743` and no prompt appears, run `tccutil reset AppleEvents <terminal bundle id>` (e.g. `net.kovidgoyal.kitty`), quit and reopen the terminal, and run it again.
- BasicTeX on macOS has only a small set of packages. When a build fails with ``File `foo.sty' not found``, run `sudo tlmgr install foo` (`tlmgr search --global --file foo.sty` finds the package name if it differs).

Jumping from the PDF back to the source:

- Zathura: works without setup. Ctrl+click in the PDF.
- Skim: in Preferences → Sync, set Preset to `Custom`, Command to the output of `which nvim`, and Arguments to `--headless -c "VimtexInverseSearch %line '%file'"`. Then Cmd+Shift+click in the PDF.

Completion and snippets:

- `texlab` (installed by Mason) completes `\ref`, `\cite`, labels and environments.
- [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) shows up in the completion menu, e.g. `BEN` → enumerate, `BFI` → figure.
- [luasnip-latex-snippets](https://github.com/iurimateus/luasnip-latex-snippets.nvim) expands as you type, e.g. `mk` → inline math, `dm` → display math, and inside math `//` → `\frac{}{}`, `sr` → `^2`, `td` → `^{}`.

## McStas

`.instr` and `.comp` files open with the `mccode` syntax in `syntax/mccode.vim`. The McStas language server (hover and completion) starts when `mcstas-language-server` is on `PATH`. Install it from [VS_for_McStas](https://github.com/Lomholy/VS_for_McStas):

```sh
pipx install "git+https://github.com/Lomholy/VS_for_McStas#subdirectory=server/python"
```

To use a conda/mamba env instead, run `pip install` with the same URL inside that env, and activate the env before you start `nvim`.
