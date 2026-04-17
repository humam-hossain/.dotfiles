# Phase 9: Fix Keymap Registry Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 09-fix-keymap-registry-integration
**Areas discussed:** Which-key registration, Snacks key scope fix, Plugin-local key wiring, Domain taxonomy fix

---

## Which-key Registration

| Option | Description | Selected |
|--------|-------------|----------|
| In misc.lua config block | Add wk.add() inside existing which-key config block | |
| Dedicated core/keymaps/whichkey.lua | New module called from core init | ✓ |
| Inline in registry.lua | Self-registering registry, loads which-key early | |

**User's choice:** Dedicated `core/keymaps/whichkey.lua`

---

## Which-key Call Site

| Option | Description | Selected |
|--------|-------------|----------|
| misc.lua config block | Plugin config block calls require('core.keymaps.whichkey').setup() | |
| core/init.lua or options.lua | Register at startup with apply_global() | ✓ |

**User's choice:** Called from core/init.lua or core/keymaps.lua

---

## Which-key Registration Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Prefix groups only | wk.add() for M.groups only; individual descs from vim.keymap.set | |
| Groups + all key descs | wk.add() for M.groups AND every registry entry | ✓ |

**User's choice:** Groups + all key descriptions from registry

---

## Snacks Key Scope Fix

| Option | Description | Selected |
|--------|-------------|----------|
| Filter snacks to own plugin keys | get_plugin_keys('folke/snacks.nvim') in lazy.lua | |
| Remove keys from snacks entirely | lazy=false means no trigger needed | |
| Keep get_all_keys(), fix dispatch | Make handler skip non-snacks keys | |
| Replace neo-tree with snacks | Eliminate the conflict at source | ✓ |

**User's choice:** Replace neo-tree with Snacks.explorer entirely
**Notes:** User explicitly said "I want to replace neotree with snacks" — this is the primary design decision of the phase

---

## Snacks Explorer Feature

| Option | Description | Selected |
|--------|-------------|----------|
| Snacks.explorer (file tree sidebar) | Full explorer replacement with sidebar | ✓ |
| Snacks.picker.files as explorer | Fuzzy picker only, no sidebar | |

**User's choice:** Snacks.explorer (full replacement)

---

## Neo-tree Capabilities to Replace

| Option | Description | Selected |
|--------|-------------|----------|
| File tree sidebar (<leader>e, \) | Core toggle/reveal | ✓ |
| Git status view | Snacks.picker.git_status() | ✓ |
| Buffer list panel | Snacks.picker.buffers() | ✓ |
| Window picker dep | Can drop | ✓ |

**Notes:** User said "full potential of snacks.explorer and completely remove neotree"

---

## Snacks Explorer Config

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal: replace_netrw + trash only | Defaults cover everything else | ✓ |
| Explicit: all major options | Verbose but clear | |

**User's choice:** `explorer = { replace_netrw = true, trash = true }`

---

## Key Layout Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Follow snacks docs exactly | Full snacks key convention (40+ keys) | ✓ |
| Keep <leader>e, remap others | Minimal remapping | |

**User's choice:** Full snacks-conventional key layout

---

## Key Adoption Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full snacks key layout | Adopt complete snacks-conventional set | ✓ |
| Minimal: neo-tree replacements only | Only 3 keys changed | |

**User's choice:** Full snacks key layout

---

## Registry Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Remove dead code | Delete M.plugin_local, explorer_keys(), neotree.lua | ✓ |
| Keep helpers, update targets | Conservative approach | |

**User's choice:** Remove all dead code

---

## Claude's Discretion

- Exact snacks key set to adopt beyond neo-tree replacements (planner cross-references docs)
- Whether nui.nvim/plenary.nvim are used by other plugins before removing
- Exact call site in core/ for whichkey.lua (keymaps.lua preferred based on codebase structure)

## Deferred Ideas

None.
