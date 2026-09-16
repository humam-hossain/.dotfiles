# Phase 22: KDE and GTK capture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 22-KDE-and-GTK-capture
**Areas discussed:** KDE package layout & file permissions, GTK per-file management & directory safety, Restow cp-through packaging & recovery rehearsal, GUARD list enforcement & kdeglobals disposition

---

## KDE Package Layout & File Permissions

### Question 1: Package Structure in stow/
| Option | Description | Selected |
|--------|-------------|----------|
| Single stow/kde/ package | Single package containing `.config/kiorc`, `.config/ktrashrc`, and `.config/kservicemenurc` (groups non-colliding KDE/KIO configs per ROADMAP KDE-01) | ✓ |
| Split packages | Separate packages (e.g. `stow/kio/`, `stow/ktrash/`, `stow/kservicemenu/`) | |
| You decide | Agent discretion (single stow/kde/ package) | |

**User's choice:** (Recommended) Single stow/kde/ package containing `.config/kiorc`, `.config/ktrashrc`, and `.config/kservicemenurc`
**Notes:** Clean packaging keeping KIO/Dolphin non-colliding rc files together.

### Question 2: Mode 0600 vs Git Permissions (Q11)
| Option | Description | Selected |
|--------|-------------|----------|
| Document 0644 harmless | Document that git's 0644 is harmless without mandatory bootstrap chmod (no secrets; KConfig setPermissions enforces 0600 on write) | ✓ |
| Explicit chmod 600 | Explicit post-stow chmod 600 in bootstrap / arch script | |
| Enforce via verify | Verify check fails or warns if permissions are not 0600 | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Document that git's 0644 is harmless and resolve without mandatory bootstrap chmod
**Notes:** Git ignores chmod between 0644 and 0600; `$HOME/.config` is already 0700 on disk.

### Question 3: Dolphin Write-Through Test (Q10)
| Option | Description | Selected |
|--------|-------------|----------|
| Two-stage test | Isolated scratch XDG fixture with kwriteconfig6/KIO plus live kiorc link survival after real setting toggle | ✓ |
| Scratch only | Automated scratch fixture only with kwriteconfig6 | |
| Manual only | Interactive verification only with Dolphin GUI | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Two-stage test: Isolated scratch XDG fixture using kwriteconfig6/KIO in assert script, plus a live verification of kiorc link survival after a real setting toggle
**Notes:** Proves KConfig preserves symlinks under real cascade.

### Question 4: Stow Call Site & Scripting
| Option | Description | Selected |
|--------|-------------|----------|
| Create arch/kde.sh | Dedicated script for stow kde | ✓ (revised in deep audit) |
| Wire into hyprland.sh | Add to arch/hyprland.sh | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Create a dedicated arch/kde.sh script
**Audit note:** During cross-phase deep review, this was revised: creating `arch/kde.sh` would bump `PAIR_COUNT` and break closed assert `phase17-unblock-assert.sh:90`. Direct stow deployment is used instead, with orchestration deferred to Phase 23.

### Question 5: SAFE-01 Live Adoption Protocol
| Option | Description | Selected |
|--------|-------------|----------|
| SAFE-01 protocol | Timestamped backup, copy to stow/kde/, dry run stow -n, atomic commit | ✓ |
| Direct copy | Direct overwrite without backup | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Follow SAFE-01 protocol

### Question 6: arch/kde.sh Scope (dolphinrc inclusion)
| Option | Description | Selected |
|--------|-------------|----------|
| Stow both | Stow both stow/kde and restow/dolphinrc | ✓ |
| Stow only kde | Stow only stow/kde | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Stow both stow/kde and restow/dolphinrc

### Question 7: Running Dolphin Processes Lifecycle
| Option | Description | Selected |
|--------|-------------|----------|
| Enforce closed | Enforce Dolphin is closed during linking/stowing (mirrors Phase 18 D-18 qBittorrent rule) | ✓ |
| Do not check | Proceed without process check | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Enforce Dolphin is closed during linking/stowing

### Question 8: Service Menu Scope
| Option | Description | Selected |
|--------|-------------|----------|
| Strictly ~/.config/kservicemenurc | Confine scope to configuration file (no custom local actions in ~/.local/share/kio/) | ✓ |
| Include ~/.local/share/kio/ | Manage ~/.local/share/kio/servicemenus/ directory as well | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Strictly confine scope to ~/.config/kservicemenurc configuration file

### Question 9: Scope Boundary for Other KDE RC Files
| Option | Description | Selected |
|--------|-------------|----------|
| Strictly KDE-01 | Only kiorc, ktrashrc, and kservicemenurc in stow/kde/ | ✓ |
| Expand scope | Add darklyrc, konsolerc, etc. | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Strictly stick to KDE-01 scope

### Question 10: KConfig Temp File Gitignore
| Option | Description | Selected |
|--------|-------------|----------|
| Adhere to Phase 19 D-41 | Only add .gitignore rule if empirical measurement observes lingering temp files; clean by default | ✓ |
| Proactively add | Add .*.tmp, .*.lock to stow/kde/.config/ | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Adhere to Phase 19 D-41 rule

### Question 11: Literal Path in ktrashrc
| Option | Description | Selected |
|--------|-------------|----------|
| Track as-is | Track /home/pera/.local/share/Trash as-is (single-machine repository per Phase 18 D-54) | ✓ |
| Template path | Template path during bootstrap | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Track as-is with /home/pera

### Question 12: Assert Drill Revert Mechanism
| Option | Description | Selected |
|--------|-------------|----------|
| Double toggle + git checkout | Toggle via kwriteconfig6, assert repo change, toggle back, git checkout -- stow/kde | ✓ |
| Single toggle + git checkout | Single toggle and git checkout | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Double write-through test + git checkout

---

## GTK Per-File Management & Directory Safety

### Question 1: Package Structure in stow/
| Option | Description | Selected |
|--------|-------------|----------|
| Single stow/gtk/ package | Single package containing `.config/gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, `gtk-4.0/settings.ini` stowed with `--no-folding` | ✓ |
| Split packages | Two packages: `stow/gtk3/` and `stow/gtk4/` | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Single package stow/gtk/ containing `.config/gtk-3.0/settings.ini`, `.config/gtk-3.0/bookmarks`, and `.config/gtk-4.0/settings.ini`

### Question 2: Directory Unfolding Enforcement
| Option | Description | Selected |
|--------|-------------|----------|
| Both | Explicitly assert `! test -L ~/.config/gtk-3.0` and `! test -L ~/.config/gtk-4.0` in assert script, enforced permanently by verify D-04 | ✓ |
| Verify only | Rely exclusively on verify's existing D-04 check | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Both: Explicitly assert ! test -L ~/.config/gtk-3.0 and ! test -L ~/.config/gtk-4.0 in phase assert, and let verify's D-04 folded-ancestor gate enforce it permanently

### Question 3: Link Severance Risk (Q6, g_file_set_contents)
| Option | Description | Selected |
|--------|-------------|----------|
| Declarative dotfiles + watchdog | Manage in stow/gtk/ as declarative dotfiles; test scratch write behavior and rely on verify as link-severance watchdog | ✓ |
| Split bookmarks to capture | Manage bookmarks in capture/ and settings.ini in stow/ | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Manage in stow/gtk/ as declarative dotfiles; test GTK file-chooser write behavior in scratch fixture and document that verify serves as the watchdog for any link severance

### Question 4: Stow Call Site & Scripting
| Option | Description | Selected |
|--------|-------------|----------|
| Create arch/gtk.sh | Dedicated script for stow gtk | ✓ (revised in deep audit) |
| Wire into hyprland.sh | Add to arch/hyprland.sh | |
| Combine script | Combined arch/desktop.sh | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Create arch/gtk.sh
**Audit note:** Revised during deep audit: no new scripts in `arch/` to protect Phase 17 regression count (`PAIR_COUNT == 18`).

### Question 5: SAFE-01 Live Adoption Protocol
| Option | Description | Selected |
|--------|-------------|----------|
| SAFE-01 protocol | Timestamped backup, copy to stow/gtk/, dry run stow -n, atomic commit | ✓ |
| Direct copy | Direct overwrite without backup | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Apply SAFE-01 protocol

### Question 6: Gitignore for gtk.css & gtk-dark.css
| Option | Description | Selected |
|--------|-------------|----------|
| Keep slash-free & add gtk-dark.css | Keep slash-free gtk.css in root .gitignore, add gtk-dark.css to generated theme block, enforce in verify | ✓ |
| Only gtk.css | Only keep gtk.css in .gitignore | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Keep slash-free gtk.css in root .gitignore, add gtk-dark.css to the generated theme block, and enforce in verify that neither appears in any managed tree

### Question 7: Legacy GTK 2.0 Scope
| Option | Description | Selected |
|--------|-------------|----------|
| Strictly out of scope | Exclude GTK 2.0 files (~/.gtkrc-2.0, ~/.config/gtkrc) per KDE-02; machine-written by nwg-look/KDE | ✓ |
| Include ~/.gtkrc-2.0 | Include in stow/gtk/ | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Strictly out of scope: Exclude GTK 2.0 files (~/.gtkrc-2.0, ~/.config/gtkrc) per KDE-02

### Question 8: Bookmarks Path Handling
| Option | Description | Selected |
|--------|-------------|----------|
| Track as-is | Track as-is with /home/pera/ paths (single-machine repository per Phase 18 D-54) | ✓ |
| Template path | Template username in bookmarks during bootstrap | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Track as-is with /home/pera/ paths

---

## Restow Cp-Through Packaging & Recovery Rehearsal

### Question 1: Package Naming for chrome-flags
| Option | Description | Selected |
|--------|-------------|----------|
| restow/chrome-flags/ | Clean semantic package name `chrome-flags` matching convention | ✓ |
| restow/chrome-flags.conf/ | Named identically to the filename | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) restow/chrome-flags/.config/chrome-flags.conf

### Question 2: Regeneration of restow/README.md
| Option | Description | Selected |
|--------|-------------|----------|
| scripts/gen-collision-map.sh | Regenerate restow/README.md via scripts/gen-collision-map.sh --restow-table (D-09, D-12) | ✓ |
| Hand edit | Update table manually | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Regenerate restow/README.md via scripts/gen-collision-map.sh --restow-table

### Question 3: Cp-Through Drill Execution
| Option | Description | Selected |
|--------|-------------|----------|
| Two-stage drill | Scratch XDG test first, then live test with clean-tree preflight assertion and git checkout recovery | ✓ |
| Live only | Live drill only | |
| Scratch only | Scratch XDG fixture drill only | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Two-stage drill: Test install-files cp-through in isolated scratch XDG first, then execute live test with clean-tree preflight assertion and git checkout recovery

### Question 4: Recovery Command Automation
| Option | Description | Selected |
|--------|-------------|----------|
| Documented prose (Phase 18 D-10) | Documented copy-pasteable command in restow/README.md without wrapper hooks | ✓ |
| Subcommand helper | Add recovery subcommand in dots-hyprland.sh | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Stick strictly to Phase 18 D-10: Documented git checkout command in restow/README.md without creating automated wrapper hooks

---

## GUARD List Enforcement & kdeglobals Disposition

### Question 1: kdeglobals Disposition
| Option | Description | Selected |
|--------|-------------|----------|
| Retire to GUARD | Retire restow/kdeglobals/ from repo to docs/archive/kdeglobals and enforce in GUARD list (live file converted to standalone local file) | ✓ |
| Keep in restow | Keep in restow as cp-through and remove from GUARD list | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Retire restow/kdeglobals/ from the repo and enforce kdeglobals in the GUARD list
**Notes:** Active measurement in Phase 21 confirmed `switchwall.sh` triggers `kde-material-you-colors` which dynamically rewrites `kdeglobals`, dirtying git status. Retiring it eliminates repo churn completely.

### Question 2: GUARD List Data Format
| Option | Description | Selected |
|--------|-------------|----------|
| guard-paths.tsv | guard-paths.tsv at repo root mirroring collision-map.tsv design (TSV format with Q7/Q8 measurement findings in header) | ✓ |
| JSON data file | arch/guard-paths.json | |
| Hardcoded array | Hardcoded array in dots-hyprland.sh verify | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) guard-paths.tsv at repo root

### Question 3: Verify GUARD Check Integration
| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated GUARD section | Dedicated section in verify checking absence from repo trees and live symlinks into repo; emits [PASS]/[FAIL] | ✓ |
| Silent pass | Only emit [FAIL] on violation | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Dedicated GUARD section in verify: checks every path in guard-paths.tsv is absent from repo trees and live link is not into repo; emits [PASS]/[FAIL] (suppressed by --quiet) matching Phase 19 conventions

### Question 4: Q8 GTK4 Theme Symlink Conflict
| Option | Description | Selected |
|--------|-------------|----------|
| Preserve live symlink | Preserve live symlink into /usr/share/themes/ as-is; document empirical measurement in guard-paths.tsv header | ✓ |
| Replace symlink | Replace ~/.config/gtk-4.0/gtk.css symlink with local plain file | |
| You decide | Agent discretion | |

**User's choice:** (Recommended) Preserve live symlink into /usr/share/themes/ as-is; document empirical measurement in guard-paths.tsv header

---

## Claude's Discretion

- Scratch fixture directory layouts in assert harness.
- Exact string formatting for `[PASS]` and `[INFO]` outputs in `run_verify()`.

## Deferred Ideas

- Phase 23: One-command full bootstrap orchestration (`BOOT-01`–`BOOT-05`).
- Future phase: Managing custom KIO context menu scripts under `~/.local/share/kio/servicemenus/` if personal actions are created.
