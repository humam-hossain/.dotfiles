# STRUCTURE

> Directory and file layout of the `.dotfiles` repository (≈200 tracked files).

## Top Level

```
.dotfiles/
├── README.md                — repo overview (nvim + tmux resource links)
├── .gitignore               — ignores ping/data/, ping/.env, .planning/tmp/, .claude/
├── arch/                    — Arch Linux install scripts (32 files)
├── debian/                  — Debian install scripts (20 files)
├── ubuntu/                  — Ubuntu install scripts (20 files)
├── scripts/                 — cross-distro helper/verification scripts (3 files)
├── issues/                  — incident post-mortems (1 file)
└── .config/                 — application configs (15 app dirs + 7 root files)
```

## arch/ — Arch Linux Provisioning (32 files)

```
arch/
├── README.md                 — full Arch install walkthrough (base system, user, bootloader, EFI)
├── define.sh                 — copies .config/define.sh to ~/
├── necessary.sh              — base-devel, networkmanager, intel-ucode, fzf, openssh, ...
├── aur.sh                    — yay (AUR helper)
├── audio.sh
├── bluetooth.sh
├── wifi.sh
├── fonts.sh                  — Nerd Fonts
├── hyprland.sh               — Hyprland + hyprpaper/hyprshot/hyprlock/swaync + systemd unit
├── quickshell.sh             — Quickshell + ddcutil/i2c (structured, symlink deploy)
├── waybar.sh                 — Waybar + custom scripts
├── rofi.sh
├── kitty.sh / alacritty.sh / wezterm.sh / xterm.sh
├── nvim.sh                   — neovim + pynvim + luarocks + tree-sitter-cli (rsync config)
├── fish.sh / zsh.sh / zsh_powerlevel.sh
├── tmux.sh
├── yazi.sh
├── btop.sh
├── nautilus.sh
├── google_chrome.sh / vscode.sh / obs_studio.sh
├── python3.sh
├── system_monitor.sh         — Docker ping monitor (structured, with verify)
├── scrutiny.sh / smartmontools (via tools.sh)
├── wakatime.sh
└── tools.sh                  — misc utilities (lazygit, fastfetch, distrobox, vlc, libreoffice, ...)
```

## debian/ and ubuntu/ — Subset Provisioning (20 files each)

Largely mirror `arch/` minus Arch-only entries (`aur.sh`, `bluetooth.sh`, `wifi.sh`, `audio.sh`, `google_chrome.sh`, `vscode.sh`, `quickshell.sh`, `zsh_powerlevel.sh`, `nautilus.sh`, `scrutiny.sh`, `system_monitor.sh` differ: ubuntu has `monitor_system.sh`; debian has `system_monitor.sh`). Add `docker.sh`, `gemini.sh`, `latex.sh`. Use `apt` instead of `pacman`/`yay`.

## scripts/ — Cross-Distro Helpers (3 files)

| File | Purpose |
|------|---------|
| `clone_repo.sh` | `gh repo list` + bulk `gh repo clone` with `notify-send` progress; skips existing dirs |
| `nvim-validate.sh` | 774-line headless Neovim validation harness (7 subcommands + `all`) |
| `nvim-audit-failures.sh` | nvim failure auditing helper |

## issues/ — Incident Post-Mortems (1 file)

| File | Purpose |
|------|---------|
| `2026-07-16_igpu-flickering-hang-no-display.md` | Detailed post-mortem: Intel UHD 770 flicker/hang caused by experimental `xe` driver + ddcutil I2C bus hammering; resolved by reverting to i915 + disabling ddcutil Waybar module |

## .config/ — Application Configs

### Root config files (shell/terminal/X)
| File | Purpose |
|------|---------|
| `.zshrc` | Zsh: Oh My Zsh + Powerlevel10k, plugins, aliases, fzf, conda aliases, `define` alias |
| `.p10k.zsh` | Powerlevel10k prompt config |
| `.zprofile` | Zsh login profile |
| `.Xresources` | X resources |
| `.tmux.conf` | Tmux config |
| `starship.toml` | Starship prompt (configured but disabled in .zshrc) |
| `define.sh` | Dictionary lookup (clipboard → dictionaryapi.dev → notify-send) |

### .config/nvim/ — Neovim (Lua, lazy.nvim)
```
.config/nvim/
├── init.lua, .luarc.json, lazy-lock.json, README.md
└── lua/
    ├── core/{options,keymaps,health,open}.lua
    ├── core/keymaps/{registry,apply,lazy,attach,whichkey}.lua
    ├── config/health.lua
    └── plugins/{blink-cmp,bufferline,colortheme,conform,git,lsp,lualine,misc,
                 project,snacks,treesitter,ufo,vim-indent-object}.lua
```
> README.md (511 lines) is the canonical doc: file inventory, rollout/update checklist, phase-by-phase change summary, post-deploy verification, rollback instructions, keymap architecture, validation harness, health schema.

### .config/hypr/ — Hyprland (4 files)
`hyprland.conf` (461 lines: monitors, autostart, workspaces, keybinds, window rules), `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`.

### .config/quickshell/ — QML desktop shell (39 files, tracked in HEAD only)
```
.config/quickshell/
├── shell.qml, Bar.qml, BarContent.qml, BarGroup.qml, ModulePill.qml
├── theme/{Colours.qml, qmldir}
├── services/  (14 singletons + qmldir)
├── widgets/   (15 widgets + qmldir)
└── popups/    (CalendarPopup, NetworkPopup, VolumeOsd)
```
> **Currently deleted in working tree** (39 unstaged deletions) — see CONCERNS.

### .config/waybar/ — Status bar
```
.config/waybar/
├── config.jsonc, style.css, mocha.css
├── PRD.md, README.md          — ping integration docs
├── data/                      — (runtime data)
└── scripts/{alerts,network,system,weather}/   — custom module scripts
```

### .config/system_monitor/ping/ — Docker ping monitor
```
.config/system_monitor/ping/
├── server.py, Dockerfile, docker-compose.yml, requirements.txt
├── ping.config, ping_plot.html
├── migrate_csv_to_sqlite.py, migrate_add_target_host.py
├── .env, .env.example, README.md, PRD.md
└── data/                      — SQLite history (gitignored)
```

### Other .config/ directories (single/few files each)
| Dir | Files | Notes |
|-----|-------|-------|
| `alacritty/` | `alacritty.toml` | |
| `btop/` | `btop.conf`, `themes/` | |
| `fish/` | `config.fish`, `auto-Hypr.fish` | |
| `kitty/` | `kitty.conf` | primary terminal |
| `rofi/` | `config.rasi`, `catppuccin-lavrent-mocha.rasi` | |
| `smartmontools/` | `collector.yml`, `smartctl-wrapper.sh` | |
| `swaync/` | `config.json`, `style.css`, `mocha.css` | notifications |
| `systemd/user/` | `hyprland-session.service` | graphical-session.target bootstrap |
| `wezterm/` | `wezterm.lua` | |
| `yazi/` | `yazi.toml`, `keymap.toml`, `theme.toml` | |

## Non-Codebase Directories (excluded from mapping)

| Dir | Status | Notes |
|-----|--------|-------|
| `.git/` | vcs | git metadata |
| `.claude/` | tooling | gitignored (Claude Code agent state) |
| `.commandcode/` | tooling | untracked (Command Code agent state) |
| `.planning/tmp/` | runtime | gitignored (nvim-validate report artifacts) |

## File-Type Distribution (tracked)

```
82 sh | 37 qml | 25 lua | 8 md | 7 conf | 5 toml | 4 theme | 4 json
4 css | 3 py  | 2 yml | 2 rasi | 2 fish | + singleton zshrc/zsh/zprofile/Xresources/txt/service/jsonc
```
