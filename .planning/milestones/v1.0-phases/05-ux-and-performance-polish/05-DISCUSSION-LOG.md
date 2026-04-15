# Phase 5: UX and Performance Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 05-ux-and-performance-polish
**Areas discussed:** Startup profiling scope, noice.nvim fate, Statusline behavior, Rollout doc format

---

## Startup Profiling Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Profile + defer obvious waste | Run :Lazy profile, add lazy events to non-essential plugins, document wins | |
| Profile + remove aggressively | Treat profiling as another audit pass — remove if cost not justified | ✓ |
| Document-only audit | Profile and record numbers, make no config changes | |

**User's choice:** Profile + remove aggressively

| Option | Description | Selected |
|--------|-------------|----------|
| No hard target | Just cut obvious waste, document result | |
| Under 100ms | Common benchmark, aim for this | ✓ |
| Under 50ms | Aggressive, may require removing heavier plugins | |

**User's choice:** Under 100ms target

---

## noice.nvim Fate

| Option | Description | Selected |
|--------|-------------|----------|
| Keep + tune | Fix `even` typo, tune cmdline popup, keep stack | |
| Replace with snacks.nvim | Modern replacement: notif + dashboard + picker in one package | ✓ |
| Remove noice, keep nvim-notify bare | Drop cmdline popup routing, keep toast notifications only | |

**User's choice:** Replace with snacks.nvim

| Option | Description | Selected |
|--------|-------------|----------|
| Notifications only (replaces noice + nvim-notify) | snacks.notif for toast notifications | ✓ |
| Dashboard (replaces alpha.nvim) | snacks.dashboard — more modern | ✓ |
| Only notifications, keep alpha | Swap notification stack, leave dashboard alone | |

**User's choice:** Both — notifications and dashboard

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom-right toasts | Standard snacks.notif — non-intrusive, auto-dismiss | ✓ |
| Bottom-center cmdline-style | Similar feel to current noice popup | |

**User's choice:** Bottom-right toasts

| Option | Description | Selected |
|--------|-------------|----------|
| No — keep fzf-lua + fugitive | Phase 5 is UI polish, not search rearchitecture | |
| Yes — adopt snacks.picker too | Full snacks consolidation, replaces fzf-lua | ✓ |

**User's choice:** Yes — adopt snacks.picker too (full consolidation)

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — update harness probes | Reflect actual stack after migration | ✓ |
| You decide | Claude handles harness update | |

**User's choice:** Yes — update harness probes

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve same keymaps, rewire to snacks | Keep <leader>ff/fg/cd/cr — no muscle-memory disruption | ✓ |
| Redesign keymaps for snacks primitives | Remap to snacks action names | |

**User's choice:** Preserve same keymaps, rewire to snacks

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ASCII art | Port existing Neovim logo to snacks dashboard | |
| No — use snacks default or minimal | Clean start, no ASCII art | ✓ |

**User's choice:** Minimal/default dashboard — no ASCII art

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — wire snacks.lazygit to a keymap | lazygit already installed, add in-editor wrapper | ✓ |
| No — keep lazygit external | Run from terminal directly | |

**User's choice:** Wire snacks.lazygit with a keymap

**Additional snacks modules selected:**
- snacks.indent (replaces indent-blankline) ✓
- snacks.words (LSP word highlights) ✓
- snacks.scroll (smooth scrolling) ✓

**Explicitly disabled:**
- snacks.image (image preview) — not needed

---

## Statusline Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| tmux statusline only, keep as-is | lualine → tmux via vim-tpipeline, laststatus=0 | ✓ |
| Show statusline inside Neovim too | Remove laststatus=0, show lualine normally | |
| Drop vim-tpipeline, use lualine normally | Remove tpipeline entirely | |

**User's choice:** Keep tmux-only approach (vim-tpipeline stays)

| Option | Description | Selected |
|--------|-------------|----------|
| globalstatus=true | One bar across all splits | ✓ |
| Per-split statusline | Each split has own statusline | |

**User's choice:** globalstatus=true

| Option | Description | Selected |
|--------|-------------|----------|
| Show lualine when no tmux | Guard: $TMUX set → laststatus=0; else → laststatus=3 | ✓ |
| Always hidden | laststatus=0 always | |

**User's choice:** Guard on $TMUX presence — visible outside tmux

| Option | Description | Selected |
|--------|-------------|----------|
| Keep existing sections, drop noice component | Clean and simple | |
| Add LSP server name | Show active LSP in lualine_x | |
| You decide | Claude picks sensible layout | ✓ |

**User's choice:** Claude's discretion for post-noice section layout

| Option | Description | Selected |
|--------|-------------|----------|
| Keep vim-tpipeline | lualine → tmux pipeline stays | ✓ |
| Remove vim-tpipeline | Simpler stack, tmux handles its own status | |

**User's choice:** Keep vim-tpipeline

---

## Rollout Doc Format

| Option | Description | Selected |
|--------|-------------|----------|
| Update existing README | Extend .config/nvim/README.md with Rollout section | ✓ |
| New dedicated file | CREATE UPDATE.md or DEPLOYMENT.md | |

**User's choice:** Update existing README

**Coverage selected:**
- Machine update checklist ✓
- Phase-by-phase change summary ✓
- Verification steps post-deploy ✓
- Rollback instructions ✓

---

## Claude's Discretion

- lualine section layout after noice component removal
- Whether to enable snacks.terminal and snacks.zen
- Exact snacks.picker keymap wiring to match fzf-lua surface
- Exact startup deferral strategy (lazy event assignments)
- Catppuccin integration flag audit beyond known stale entries

## Deferred Ideas

None — discussion stayed within phase scope.
