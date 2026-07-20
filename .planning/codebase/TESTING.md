# TESTING

> Validation and verification strategy for the `.dotfiles` repository.

## Summary

There is **no unit-test framework** (no Bats, no busted/luaunit, no pytest suite). Verification is **shell-orchestrated and headless**, focused almost entirely on the Neovim config, plus post-install `verify()` functions in the structured provisioning scripts. This is appropriate for a dotfiles repo where "tests" are really "does the environment come up correctly."

## Neovim Validation Harness — `scripts/nvim-validate.sh`

The centerpiece of the repo's verification strategy. A 774-line Bash script that runs Neovim headlessly against the **repo** config (not the installed one) via:
```
nvim --headless -u "$REPO_ROOT/.config/nvim/init.lua" --cmd "set rtp^=$REPO_ROOT/.config/nvim"
```

### Subcommands

| Subcommand | What it does | Failure signal |
|------------|--------------|----------------|
| `startup` | `nvim --headless "+qa"` smoke; deferred quit after 50ms | non-zero exit OR `Error\|E5108\|E484\|stack traceback` in log |
| `sync` | `Lazy! sync` with **120s timeout** | timeout (124), non-zero, or error keywords |
| `smoke` | `pcall(require, ...)` each high-risk plugin module (snacks, lualine, lspconfig, conform, treesitter, blink.cmp, gitsigns, ufo, bufferline, which-key, render-markdown) | any load failure → writes `SMOKE_FAIL`, exits `cq` |
| `health` | invokes `core.health.snapshot()`, writes `health.json` | any plugin `loaded=false`, or required tool (`git`,`rg`) missing |
| `checkhealth` | headless `:checkhealth`, dumps buffer to `checkhealth.txt` | unexpected `ERROR:` lines (tolerates documented headless/env-only families) |
| `keymaps` | probes lazy key dispatcher against Phase 7 regression action-string types (`<cmd>…`, `<C-…>`, `:…`) via `pcall` | any probe throws → `keymap-regression.log` |
| `formats` | calls `format_on_save` guard directly with synthetic buffers (nofile, unnamed, acwrite) | wrong return value → `format-regression.log` |
| `all` | runs startup→sync→smoke→health→checkhealth→keymaps→formats, **fail fast** | first failure aborts |

### Artifacts (written to `.planning/tmp/nvim-validate/`, gitignored)
`startup.log`, `sync.log`, `smoke.log`, `health.json`, `health.log`, `checkhealth.txt`, `keymap-regression.log`, `format-regression.log`.

### Health snapshot schema (`core.health.snapshot`)
```json
{
  "neovim_version": "<semver>",
  "timestamp": "<ISO-8601 UTC>",
  "plugins": [ { "name": "<module>", "loaded": true, "error": null } ],
  "tools":   [ { "name": "<binary>", "available": true, "path": "...", "affected_feature": "...", "install_hint": "..." } ],
  "lazy":    { "installed": 42, "loaded": 42, "problems": [] }
}
```

### Interactive counterpart
`:checkhealth config` (backed by `lua/config/health.lua`) is the in-editor first-line diagnostic for setup issues not caught by the scripted harness.

### When to run
- After any change in `.config/nvim/lua/plugins/*.lua` → `startup`
- After refreshing `lazy-lock.json` → `all`

## Provisioning-Script Verification (`verify()`)

The structured script generation includes explicit post-install assertions:

| Script | Verifications |
|--------|---------------|
| `arch/system_monitor.sh` | `docker compose ps` shows running; `/api/status` responds with valid JSON (`text`,`class` keys) via retry loop (10×, 1s); `/api/today` has `bars`; web UI serves `<html>`; `ping.config` accessible inside container; waybar fetcher returns valid JSON |
| `arch/quickshell.sh` | `command -v quickshell`, `command -v ddcutil`, `~/.config/quickshell` is a symlink, `shell.qml` reachable through symlink, `/etc/modules-load.d/i2c.conf` exists |

Legacy scripts (nvim.sh, hyprland.sh, tools.sh) have **no verify step** — they rely on `set -e` to fail fast on command errors only.

## Manual / Interactive Verification

Documented in `.config/nvim/README.md` as a post-deploy checklist:
1. `./scripts/nvim-validate.sh all` (expected final line `==> all PASS`)
2. In-editor `:checkhealth` (no ERRORs from snacks/lazy/lspconfig/mason/blink/gitsigns/lualine/treesitter)
3. Manual keymap smoke (`<leader>ff`, `<leader>fg`, `<leader>gg`, `<leader>cd`, `<leader>cr`, notification toast, `<leader>o`)
4. Statusline placement check (inside vs outside tmux)
5. Dashboard check (snacks dashboard on empty launch)

## Manual LSP Verification (documented)

- `tail -50 ~/.local/state/nvim/lsp.log`
- `:checkhealth vim.lsp` + `:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))`
- Per-language expected-LSP table (lua→lua_ls, py→ty, js/ts→ts_ls, rs→rust_analyzer, go→gopls, c→clangd, md→marksman, sh→bashls, json/html/css/yaml servers)
- Common-error table with fixes (eslint_d config, shellcheck missing, lua_ls root_dir, jdtls Java 21)

## Rollback Strategy (documented, not automated)

nvim README documents four rollback granularities:
- **A. Single-file**: `git checkout <commit> -- <file>`
- **B. Phase-level**: `git revert` of plan commits (`feat({phase}-{plan}):` / `docs({phase}-{plan}):`)
- **C. Plugin-set**: restore `lazy-lock.json` + `:Lazy restore`
- **D. Full phase**: `git revert <oldest>..<newest>`
Prefers `git revert` over `git reset --hard` to keep history linear and pullable by other machines.

## What Is NOT Tested

- **Quickshell QML** — no validation; `verify_install` only checks the symlink exists, not that the shell renders
- **Waybar custom modules** — no automated test; ping module has manual troubleshooting steps in README only
- **Hyprland config** — no validation; errors surface only at session start
- **Shell configs** (.zshrc, fish, tmux) — no validation
- **Install scripts themselves** — not linted/shellchecked in CI (shellcheck is mentioned only as an LSP consideration, not enforced)
- **Cross-distro parity** — debian/ubuntu scripts have no verify step and no parity tests against arch

## CI

**None.** All validation is manual/local. There is no GitHub Actions workflow, pre-commit hook, or automated runner.
