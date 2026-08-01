# Phase 5: Fork & Submodule Pin - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-25
**Phase:** 5-Fork & Submodule Pin
**Areas discussed:** Fork bootstrap path, Submodule add method, Initial pin selection, Post-pin clone layout

---

## Fork bootstrap path

| Option | Description | Selected |
|--------|-------------|----------|
| gh repo fork (Recommended) | Create fork via gh, then rewire remotes | ✓ |
| Manual fork on github.com | User creates fork in browser | |
| You decide | Agent picks least-friction path | |

**User's choice:** gh repo fork (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Retarget sibling clone (Recommended) | Keep ~/github_repo/dots-hyprland; origin→fork | |
| Fresh clone of the fork | Leave sibling; clone fork fresh | |
| You decide | Agent chooses | |
| Other (free text) | — | ✓ |

**User's choice:** Other — *“what exists in ~/github_repo/dots-hyprland/ is irrelevant. Do things fresh, what about submodule?”*
**Notes:** Sibling ignored; canonical path will be the submodule.

| Option | Description | Selected |
|--------|-------------|----------|
| Public (Recommended) | Default fork visibility | ✓ |
| Private | Needs auth for submodule clones | |
| You decide | Default public | |

**User's choice:** Public (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| SSH origin + HTTPS upstream (Recommended) | Match .dotfiles SSH; upstream read-only HTTPS | ✓ |
| SSH for both | Both via git@ | |
| HTTPS for both | Credential helper for push | |

**User's choice:** SSH origin + HTTPS upstream (Recommended)
**Notes:** —

---

## Submodule add method

| Option | Description | Selected |
|--------|-------------|----------|
| git submodule add fork URL (Recommended) | From REPO_ROOT add vendor/dots-hyprland | ✓ |
| Clone first, then convert to submodule | More steps; gitlink risk | |
| You decide | Research-recommended path | |

**User's choice:** git submodule add fork URL (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Always --recursive (Recommended) | Nested shapes present (OWN-03) | ✓ |
| Outer only at first | Nest later | |
| You decide | Default recursive | |

**User's choice:** Always --recursive (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| origin=fork + upstream=end-4 (Recommended) | OWN-01 remotes | ✓ |
| origin=fork only | upstream later | |
| You decide | Both remotes | |

**User's choice:** origin=fork + upstream=end-4 (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Commit pin only (Recommended) | No branch= auto-track in .gitmodules | ✓ |
| Also set branch = main | Helps --remote updates | |
| You decide | Prefer explicit pin | |

**User's choice:** Commit pin only (Recommended)
**Notes:** —

---

## Initial pin selection

| Option | Description | Selected |
|--------|-------------|----------|
| Fork default-branch tip at add time (Recommended) | Pin HEAD when submodule added | ✓ |
| Match sibling SHA 1a9ffb78 | Use sibling checkout commit | |
| You name a SHA/tag later | Defer pin choice | |

**User's choice:** Fork default-branch tip at add time (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Trust fork tip as-is (Recommended) | No extra merge dance in Phase 5 | ✓ |
| Fetch upstream and pin that tip | Force newest end-4 | |
| You decide | Only if stale | |

**User's choice:** Trust fork tip as-is (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| .gitmodules + gitlink together (Recommended) | Atomic parent pin commit | ✓ |
| Separate commits OK | Split metadata | |
| You decide | Prefer atomic | |

**User's choice:** .gitmodules + gitlink together (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Full OWN-01/02/03 checklist (Recommended) | remotes + pin + recursive shapes | ✓ |
| Outer pin only | Nested later | |
| You decide | Match ROADMAP criteria | |

**User's choice:** Full OWN-01/02/03 checklist (Recommended)
**Notes:** —

---

## Post-pin clone layout

| Option | Description | Selected |
|--------|-------------|----------|
| vendor/dots-hyprland only (Recommended) | Single canonical path | ✓ |
| Either vendor or sibling | Dual checkouts OK | |
| You decide | One path documented | |

**User's choice:** vendor/dots-hyprland only (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Leave it alone (Recommended) | No delete/rewire of sibling | ✓ |
| Delete the sibling directory | Only vendor remains | |
| You decide | Leave untouched (safer) | |

**User's choice:** Leave it alone (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| --recurse-submodules (or update --init --recursive) (Recommended) | Stock git only | ✓ |
| Custom bootstrap script in Phase 5 | Helper for vendor+shapes | |
| You decide | Stock git; docs Phase 9 | |

**User's choice:** --recurse-submodules (or update --init --recursive) (Recommended)
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| Pin only — no install (Recommended) | No setup/wrapper/hooks | ✓ |
| Also draft the wrapper skeleton | Scope into Phase 6 | |
| You decide | Keep pin-only | |

**User's choice:** Pin only — no install (Recommended)
**Notes:** —

---

## Claude's Discretion

- Exact `gh repo fork` flags and temp vs submodule-only clone flow
- Parent pin commit message wording
- OWN verification command sequence shape
- Whether short SHA appears in any comment beyond gitlink

## Deferred Ideas

- Phase 6 wrapper, Phase 7 install/session, Phase 8 retirement, Phase 9 docs
- Optional sibling directory deletion (operator, not phase work)
- Custom submodule bootstrap script (declined for Phase 5)
