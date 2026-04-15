# Neovim config

## Phase 2: Central Command and Keymap Architecture

This phase centralizes all custom keymaps under a declarative registry for discoverability and maintainability.

### Domain Taxonomy

All leader-prefixed keymaps follow explicit domain prefixes:

| Prefix | Domain | Description |
|--------|--------|-------------|
| `<leader>f` | search | Fuzzy find, grep, files, buffers |
| `<leader>c` | code | LSP goto, references, actions |
| `<leader>g` | git | Status, blame, hunk navigation |
| `<leader>e` | explorer | File tree, reveal |
| `<leader>b` | buffers | Buffer list, close |
| `<leader>w` | windows | Window navigation, resize |
| `<leader>t` | toggles | Fold, inlay hints |
| `<leader>s` | save | Write, session |

### Preserved Direct Keys

These non-leader keys are intentionally preserved:

| Key | Action |
|-----|--------|
| `jk` | Switch to normal mode |
| `<C-h>` | Window left |
| `<C-j>` | Window down |
| `<C-k>` | Window up |
| `<C-l>` | Window right |
| `<C-_>` | Toggle comment |
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |

### Mapping Scopes

- **global**: Applied immediately at startup via `core.keymaps.apply`
- **lazy**: Loaded on key trigger via `lazy.nvim` — defined in registry, consumed by plugin specs
- **buffer**: Applied on LSP attach via `core.keymaps.attach`
- **plugin-local**: Context-specific (neo-tree windows, treesitter incremental)

### Registry Architecture

```
lua/core/keymaps/
├── registry.lua   -- Declarative source of truth
├── apply.lua      -- Applies global mappings
├── lazy.lua       -- Compiles lazy.nvim keys specs
├── attach.lua     -- Applies buffer-local mappings
└── whichkey.lua  -- Registers which-key groups
```

All custom mappings are declared in `registry.lua` with: `id`, `lhs`, `mode`, `desc`, `domain`, `scope`, `plugin`, `action`.

## Phase 3: Validation Harness

The repo ships a shell-orchestrated headless validation harness so maintainers can catch startup, sync, health, and plugin-load regressions without launching an interactive Neovim.

### Entrypoint

| Command | Purpose |
|---------|---------|
| `./scripts/nvim-validate.sh startup` | Run `nvim --headless "+qa"` against this config; fail on any error message or non-zero exit |
| `./scripts/nvim-validate.sh sync` | Run headless `Lazy! sync` with a 120s timeout; fail on timeout or stack traceback |
| `./scripts/nvim-validate.sh health` | Invoke `core.health.snapshot` and write JSON to `.planning/tmp/nvim-validate/health.json`; fail on any plugin with `loaded=false` |
| `./scripts/nvim-validate.sh smoke` | pcall-require the high-risk plugin modules one by one; fail on any load failure |
| `./scripts/nvim-validate.sh all` | Run startup, sync, smoke, health in order; fail fast |

### Report Output

All reports are written to `.planning/tmp/nvim-validate/` (gitignored):

- `startup.log` — stdout+stderr from headless startup
- `sync.log` — output from `Lazy! sync`
- `smoke.log` — per-plugin pcall results
- `health.json` — machine-readable snapshot (schema below)
- `health.log` — stderr from the health invocation

### Health Snapshot Schema

`health.json` is produced by `require('core.health').snapshot({...})` and conforms to:

```json
{
  "neovim_version": "<semver>",
  "timestamp": "<ISO-8601 UTC>",
  "plugins": [ { "name": "<module>", "loaded": true, "error": null } ],
  "tools":   [ { "name": "<binary>", "available": true, "path": "/usr/bin/..." } ],
  "lazy":    { "installed": 42, "loaded": 42, "problems": [] }
}
```

Missing external tools are reported as `available: false` with install hints printed by the shell wrapper. Missing tools do NOT fail the harness (per Phase 3 D-07 graceful degradation policy); only missing plugins fail.

### Missing Tool Policy

Per Phase 3 decisions D-07 through D-09:

- Runtime startup does NOT emit `vim.notify` warnings when external tools (formatters, LSP binaries) are missing. Startup stays graceful and silent.
- Missing tools are surfaced ONLY through `./scripts/nvim-validate.sh health` and the `core.health.snapshot` JSON.
- Each tool entry in `health.json` includes `affected_feature` (what stops working) and `install_hint` (how to install).
- Tool-sensitive plugins (conform.nvim formatters, mason-managed LSPs) degrade silently when their binary is absent; the health command is the single source of truth for what is missing.

Example missing-tool output from `./scripts/nvim-validate.sh health`:

```
MISSING TOOLS:
WARN: missing tool 'shfmt' — affects Shell formatting — install: go install mvdan.cc/sh/v3/cmd/shfmt@latest
WARN: missing tool 'gopls' — affects Go LSP — install: mason: :MasonInstall gopls
```

### When To Run

- After any change in `.config/nvim/lua/plugins/*.lua`: `./scripts/nvim-validate.sh startup`
- After refreshing `lazy-lock.json`: `./scripts/nvim-validate.sh all`
- Before concluding Phase 3 or starting Phase 4: `./scripts/nvim-validate.sh all`

## Phase 1: Reliability and Portability Baseline

This config is designed to work across Arch Linux, Debian/Ubuntu, and Windows with a unified buffer-first lifecycle model.

### Buffer, Window, and Tab Model

- **Buffer-first**: `<C-q>` closes the current buffer with confirmation if modified
- **Windows are layout only**: `<leader>xs` closes only the current split
- **Tabs are explicit workspaces**: Not affected by normal buffer-close commands

### Autosave Policy

- Autosave runs only on `FocusLost` for normal file buffers
- Checks: `buftype == ""`, `modifiable`, `modified`, non-empty filename
- Special buffers (terminal, quickfix, prompt, nofile, help) are never auto-written

### External Open Behavior

- `<C-S-o>` opens the current buffer's file with the system default application
- Neo-tree `<c-o>` opens the selected node with the same helper
- Uses `vim.ui.open()` for cross-platform support (Linux, macOS, Windows)

### Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Arch Linux | Tested | Uses system default app via vim.ui.open |
| Debian/Ubuntu | Tested | Same as Arch |
| Windows | Tested | Uses explorer.exe via vim.ui.open |

### Smoke Checklist

1. **Load test**: `nvim --headless "+qa"`
2. **External open**: Press `<C-S-o>` - should open in system default app
3. **Neo-tree open**: In neo-tree, press `<c-o>` on a file - should open externally
4. **Buffer close**: Press `<C-q>` on modified buffer - should prompt for confirmation
5. **Split close**: Press `<leader>xs>` - should close only current split
6. **Autosave**: Edit a file, switch focus away - should auto-save (FocusLost)

## Resources

- typecraft yt: [youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn](https://www.youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn)
- Andrew Courter: [youtube.com/watch?v=NG7P_fPeuA8](https://www.youtube.com/watch?v=NG7P_fPeuA8)
- Henry Misc: [youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx](https://youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx)
- MrJackob (Much more detailed): [youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG](https://www.youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG)
