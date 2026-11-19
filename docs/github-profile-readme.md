# GitHub Profile README (humam-hossain)

Operator writeup for the self-updating terminal-themed GitHub Profile README at [`github.com/humam-hossain`](https://github.com/humam-hossain/humam-hossain).

## What it is

A single-card Neofetch-style profile that renders as an inline SVG directly on the GitHub profile page. Two SVGs are generated — `dark_mode.svg` and `light_mode.svg` — and GitHub's native `<picture>` media query selects the correct one based on the visitor's color scheme. The design language follows [Andrew6rant](https://github.com/Andrew6rant/Andrew6rant): monospace text, dot-leader key-value pairs, ASCII art on the left, system/skills/projects on the right, all inside a single rounded-corner card.

```
┌─────────────────────────────────────────────────────────────┐
│  ▄▄     ▄▄     humam@workstation ————————————————————————— │
│  ██     ██     . OS: ................. Arch Linux x86_64   │
│  █████████     . Host: ............... Workstation          │
│  ██     ██     . Kernel: ............. Systems, SQA & Robot │
│  ▀▀     ▀▀ _  . IDE: ................ Neovim, VSCode       │
│               . Shell: .............. zsh 5.9              │
│  HUMAM HOSSAIN . Uptime: ............. 6y 2mo              │
│  =============                                              │
│  [AI & ROBOT]   - Featured Projects ————————————————————— │
│  arch-linux-64  . adb-permission-manager: .... TUI / ADB   │
│  workstation    . Voice: .................... STT hotkeys   │
│                                                             │
│                 - Contact ———————————————————————————————— │
│                 . Email: ...... muhammed.humam.hossain@...  │
└─────────────────────────────────────────────────────────────┘
```

## Repository layout

```
humam-hossain/
├── profile_config.json        ← single source of truth for all profile data
├── dark_mode.svg              ← generated dark-theme SVG
├── light_mode.svg             ← generated light-theme SVG
├── README.md                  ← <picture> embed (6 lines, never hand-edited)
├── scripts/
│   ├── configure_profile.py   ← interactive TUI wizard (~1 270 LOC)
│   └── build_profile.py       ← SVG compiler & README updater (~600 LOC)
├── data/
│   └── cache.json             ← cached GitHub stats / streak metrics
├── tests/
│   ├── test_configure.py      ← wizard unit tests
│   └── test_neofetch.py       ← SVG builder unit tests
└── .github/workflows/
    └── profile-updater.yml    ← daily cron at 00:17 UTC
```

## Infrastructure cost

$0.00. The daily GitHub Actions workflow runs on `ubuntu-latest` using the free unlimited tier for public repositories. Both Python scripts use the standard library only — zero pip packages.

## Configuration: `profile_config.json`

All profile content lives in one JSON file. The interactive wizard writes to it; the builder reads from it. The schema:

| Key | Purpose |
|---|---|
| `user` | GitHub username, display name, prompt header (`humam@workstation`) |
| `system_info` | Key-value rows in the System Info block (OS, Host, Kernel, IDE, Shell) |
| `skills` | Dot-leader skill categories (e.g. `Languages.Code: Python, C/C++, ...`) |
| `featured_projects` | Repos + one-line descriptions shown in the Featured Projects block |
| `contacts` | Email, LinkedIn, Portfolio — rendered at the bottom of the card |
| `telemetry` | Uptime start date, toggle flags for GitHub stats / LOC counters |
| `ascii_art` | Array of strings rendered on the left side of the card |

## Interactive wizard

```bash
python3 scripts/configure_profile.py
```

A full-screen terminal TUI (cbreak mode, alternate screen) with five steps:

1. **Select Featured Projects** — multi-select list of all GitHub repos, ordered by latest commit. Previously selected repos from the last run appear at the top with their custom descriptions preserved.
2. **Edit Project Descriptions** — inline editing of the one-line description for each selected project. Supports `J`/`K` reordering.
3. **Technical Skills & Categories** — manage skill categories: add, delete entire categories, or enter a category to add, delete, rename, and reorder individual skills.
4. **System Telemetry & Specs** — configure prompt header, OS, Host, Kernel/Role, IDE, Shell, and uptime start date.
5. **Contacts** — edit email, LinkedIn, portfolio handles and URLs.
6. **ASCII Art** — choose between Arch Linux logo, monogram banner, or keep custom artwork. Remembers the last selection.

### Controls

| Key | Action |
|---|---|
| `j` / `k` / `↓` / `↑` | Navigate |
| `h` / `l` | Page scroll |
| `Space` | Toggle checkbox |
| `Enter` | Confirm / enter sub-menu / edit field |
| `/` | Search/filter |
| `d` / `x` / `Delete` | Delete selected item |
| `J` / `K` | Reorder (move selected item up/down) |
| `a` | Add new item |
| `c` | Continue to next step |
| `q` / `Esc` | Quit / back |

### Text editor

The inline text editor supports `Home`, `End`, `Delete`, `Ctrl+U` (kill to start), `Ctrl+K` (kill to end), `Ctrl+W` (kill word), and horizontal scrolling. A reverse-video block cursor is rendered in-buffer, and the hardware cursor is positioned to match.

## Building SVGs

```bash
python3 scripts/build_profile.py
```

Reads `profile_config.json` + `data/cache.json`, generates both SVGs and updates `README.md`. When a `GITHUB_TOKEN` is available (GitHub Actions), it fetches live stats from the GraphQL API; otherwise it uses cached baselines.

The builder:
- Renders the left column (ASCII art) and right column (system info, skills, projects, contacts) as `<tspan>` elements in a monospace `<text>` block.
- Applies dot-leader alignment (`justify_dot_leader`) so every key-value row totals the same character width.
- Strips empty categories (a category where all skills have been deleted won't leave a blank line).
- Writes identical structure to both `dark_mode.svg` (bg `#161b22`, text `#c9d1d9`) and `light_mode.svg` (bg `#f6f8fa`, text `#1f2328`).

## GitHub Actions automation

The workflow at `.github/workflows/profile-updater.yml`:

- **Schedule:** daily at 00:17 UTC (offset to avoid runner congestion).
- **Triggers:** push to `main` touching `scripts/`, `profile_config.json`, or the workflow file itself.
- **Job:** `sync-profile` on `ubuntu-latest` — runs the Python builder with `GITHUB_TOKEN`, then auto-commits updated SVGs and cache if anything changed.
- **Dry run:** `workflow_dispatch` with `dry_run: true` to simulate without committing.
- **Concurrency:** single group, no cancel-in-progress, so overlapping runs queue instead of race.

## Running tests

```bash
pytest
```

19 tests covering:
- Repository fetch ordering and last-change prioritization
- Skills item parsing, formatting, deletion, and category deletion
- ASCII art state preservation across wizard runs
- ANSI escape stripping and line padding
- Non-interactive fallback paths

## Relationship to this dotfiles repo

The `humam-hossain` profile repo is a standalone repository at `~/github_repo/humam-hossain`, not part of the dotfiles stow tree. This writeup lives here as operator documentation because:

1. The wizard (`configure_profile.py`) is a local-only tool run from the same workstation these dotfiles manage.
2. The profile's terminal aesthetic (Arch Neofetch, monospace, ANSI colors) is a downstream expression of the same desktop shell and editor configs maintained in this repo.
3. If the machine is rebuilt from these dotfiles, this document tells you how to reconfigure and regenerate the profile from scratch.

### Cold-start after machine rebuild

```bash
cd ~/github_repo/humam-hossain
python3 scripts/configure_profile.py   # interactive setup
python3 scripts/build_profile.py       # generate SVGs
git add -A && git push origin main     # deploy
```

The GitHub Actions cron will keep it updated daily from there.
