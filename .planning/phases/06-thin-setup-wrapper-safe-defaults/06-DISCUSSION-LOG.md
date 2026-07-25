# Phase 6: Thin Setup Wrapper & Safe Defaults - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-25
**Phase:** 6-Thin Setup Wrapper & Safe Defaults
**Areas discussed:** CLI surface & invocation, Safe-default flag injection, Backup gate strictness, Preflight & smoke-test scope

---

## CLI surface & invocation

### How should the operator invoke the wrapper?

| Option | Description | Selected |
|--------|-------------|----------|
| Subcommands mirror setup | `install\|install-deps\|install-setups\|install-files [flags]` | ✓ |
| Bare passthrough only | All args → `./setup "$@"` with no first-arg parsing | |
| You decide | Agent picks best match for arch + WRAP-01 | |

**User's choice:** Subcommands mirror setup (Recommended)

### What should bare `arch/dots-hyprland.sh` (no args) do?

| Option | Description | Selected |
|--------|-------------|----------|
| Print help and exit 0 | Usage + safe defaults; never empty ./setup | ✓ |
| Print help and exit non-zero | Same help, usage error exit | |
| Error only, no help dump | Short missing-subcommand message | |

**User's choice:** Print help and exit 0 (Recommended)

### Should the wrapper expose a local help surface?

| Option | Description | Selected |
|--------|-------------|----------|
| Wrapper help + passthrough -h | Local docs + `install -h` → ./setup | ✓ |
| Only forward to ./setup -h | No wrapper-authored help | |
| You decide | Thinnest option that teaches defaults | |

**User's choice:** Wrapper help + passthrough -h (Recommended)

### Which setup subcommands may the wrapper accept?

| Option | Description | Selected |
|--------|-------------|----------|
| WRAP-01 four only | install, install-deps, install-setups, install-files | ✓ |
| Four + explicit allowlist extras | Also help/checkdeps; block uninstall/exp | |
| Full passthrough | Any ./setup subcommand | |

**User's choice:** WRAP-01 four only (Recommended)

**Notes:** User chose "Next area" after first round (no extra CLI questions).

---

## Safe-default flag injection

### Which subcommands get safe defaults?

| Option | Description | Selected |
|--------|-------------|----------|
| install + install-files only | File-touching paths only | ✓ |
| All four WRAP-01 subcommands | Always inject even for deps/setups | |
| You decide | Only where ./setup honors flags | |

**User's choice:** install + install-files only (Recommended)

### How should operators override or drop safe defaults?

| Option | Description | Selected |
|--------|-------------|----------|
| Passthrough merges; no auto-strip | Always prepend defaults; user flags append | ✓ |
| Escape hatch --raw / --no-safe-defaults | Pure passthrough only with hatch | |
| Detect and skip injecting if already passed | Dedup inject if user already set flags | |

**User's choice:** Passthrough merges; no auto-strip (Recommended)

### Should --skip-sysupdate (-s) be in the default profile?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, default -s | Avoid unattended pacman -Syu | ✓ |
| No — leave sysupdate to upstream | Only --core --skip-hyprland | |
| You decide | Least-surprise for install style | |

**User's choice:** Yes, default -s (Recommended)

### Auto-pass --force / --skip-allgreeting?

| Option | Description | Selected |
|--------|-------------|----------|
| Never auto-force | No -f; greetings not default | ✓ |
| Default skip greetings only | --skip-allgreeting; still no -f | |
| You decide | Keep defaults minimal | |

**User's choice:** Never auto-force (Recommended)

### Announce injected defaults?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — log injected flags | [CONFIG] + full argv | ✓ |
| Silent inject | No extra messaging | |
| You decide | Match arch verbosity | |

**User's choice:** Yes — log injected flags (Recommended)

### Final ./setup argv order?

| Option | Description | Selected |
|--------|-------------|----------|
| subcommand, defaults, user flags | User can append after | ✓ |
| subcommand, user flags, defaults | Defaults always win | |
| You decide | Best WRAP-04 intent | |

**User's choice:** subcommand, then defaults, then user flags (Recommended)

### User already passes --core / --skip-hyprland?

| Option | Description | Selected |
|--------|-------------|----------|
| Still inject; duplicates OK | Simple always-prepend | ✓ |
| Deduplicate before exec | No double long flags | |
| You decide | Prefer simplicity | |

**User's choice:** Still inject; duplicates OK (Recommended)

### Is --skip-hyprland-entry part of defaults?

| Option | Description | Selected |
|--------|-------------|----------|
| No — only full --skip-hyprland | Entry-only still renames conf | ✓ |
| Yes, also inject entry skip | Belt-and-suspenders | |
| You decide | Follow research | |

**User's choice:** No — only full --skip-hyprland (Recommended)

**Notes:** User asked for a second round of flag questions, then moved on.

---

## Backup gate strictness

### How hard is the backup gate?

| Option | Description | Selected |
|--------|-------------|----------|
| Hard interactive gate | Confirm before install/install-files | ✓ |
| Soft reminder only | Warn and continue | |
| Hard if TTY; soft non-interactive | Dual mode | |

**User's choice:** Hard interactive gate (Recommended)

### Operator passes --skip-backup?

| Option | Description | Selected |
|--------|-------------|----------|
| Refuse unless explicit override | Need --allow-skip-backup | ✓ |
| Warn loudly but allow | Pass through after warning | |
| Strip --skip-backup silently | Always force backup | |

**User's choice:** Refuse unless explicit override (Recommended)

### Backup messaging content?

| Option | Description | Selected |
|--------|-------------|----------|
| Backup dir + hypr/QS risk summary | Full risk education | ✓ |
| Minimal one-liner | Short ensure-backups only | |
| You decide | WRAP-03 without essay | |

**User's choice:** Backup dir + hypr/QS risk summary (Recommended)

### Gate on install-deps / install-setups?

| Option | Description | Selected |
|--------|-------------|----------|
| No — files-touching only | Gate install + install-files | ✓ |
| Yes — all four | Always prompt | |
| You decide | Match overwrite risk | |

**User's choice:** No — files-touching only (Recommended)

---

## Preflight & smoke-test scope

### Preflight checks before ./setup?

| Option | Description | Selected |
|--------|-------------|----------|
| vendor setup executable + .git present | No auto submodule update | ✓ |
| Also require nested shapes LICENSE | OWN-03-style check every run | |
| Minimal: only test -x setup | Skip .git check | |

**User's choice:** vendor setup executable + .git present (Recommended)

### Auto-fix preflight failures?

| Option | Description | Selected |
|--------|-------------|----------|
| Never auto-fix — print fix commands | Stock git philosophy | ✓ |
| Auto-run submodule update --init --recursive | Attempt recovery once | |
| You decide | Prefer non-mutating | |

**User's choice:** Never auto-fix — print fix commands (Recommended)

### Phase 6 smoke coverage?

| Option | Description | Selected |
|--------|-------------|----------|
| Help + dry path only | No live install mutation | ✓ |
| Help + real install-deps if dry | Skip if no dry-run | |
| You decide | Match roadmap 06-03 | |

**User's choice:** Help + dry path only (Recommended)

### verify() like arch/quickshell.sh?

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight preflight only in Phase 6 | LIVE in Phase 7; POLISH-01 later | ✓ |
| Add verify subcommand now | Early POLISH-01 | |
| You decide | Keep Phase 6 thin | |

**User's choice:** Lightweight preflight only in Phase 6 (Recommended)

---

## Claude's Discretion

- Confirm prompt wording / yes-token for hard backup gate
- Exact `[LABEL]` echo vocabulary within arch conventions
- Structured `main()` layout details
- Smoke test packaging form (plan assertions vs SUMMARY commands)

## Deferred Ideas

- Live install / session hooks / dual-run — Phase 7
- Product retirement — Phase 8
- Operator docs — Phase 9
- verify subcommand — POLISH-01
- exp-update / exp-merge via wrapper — out of scope
- Non-interactive backup-gate mode — not decided
- Nested shapes LICENSE preflight every run — declined for Phase 6
