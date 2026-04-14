# Phase 1: Reliability and Portability Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 1-Reliability and Portability Baseline
**Areas discussed:** Buffer, Window, and Tab Model; Close Semantics; Autosave Policy; External Open Behavior

---

## Buffer, Window, and Tab Model

| Option | Description | Selected |
|--------|-------------|----------|
| Buffer-first | Close buffer kills current buffer only; windows are layout only; tabs are explicit workspaces and never touched by buffer-close shortcuts | ✓ |
| Window-first | Close should usually close the current split/window; buffer closing is secondary | |
| Hybrid | One key closes window in splits, but closes buffer when only one window exists | |

**User's choice:** `1`
**Notes:** User selected the buffer-first model.

---

## Close Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Close current buffer only | `<C-q>` never exits whole Neovim and respects normal save-confirm behavior if dirty | ✓ |
| Close current window only | Close the active split/window even if buffer remains alive elsewhere | |
| Keep smart behavior | Window if split, buffer if not, quit app if last one | |

**User's choice:** `1`
**Notes:** User wants `<C-q>` to close the current buffer only, not the application.

---

## Autosave Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal autosave | Save on `FocusLost` and similarly safe cases only; never on every buffer leave or text change; only normal file buffers | ✓ |
| Moderate autosave | Save on `FocusLost` and `InsertLeave`; no delayed text-change save; only normal file buffers | |
| Aggressive autosave | Keep near-current behavior with better exclusions | |

**User's choice:** `1`
**Notes:** User wants minimal autosave, limited to conservative triggers and normal file buffers.

---

## External Open Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Default app helper | One OS-aware helper opens files/dirs/URLs with the system default app from keymaps and neo-tree | ✓ |
| Browser-only | Keep behavior specifically for browser-style opening | |
| Split behavior | One helper with typed behavior for files, directories, and URLs | |

**User's choice:** `1`
**Notes:** User wants one shared OS-aware helper for generic external opening.

---

## the agent's Discretion

- Exact helper/module placement
- Exact autosave exclusion list and guard implementation
- Exact keymap descriptions and internal command names

## Deferred Ideas

None.
