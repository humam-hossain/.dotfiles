---
phase: 22-kde-and-gtk-capture
plan: 02
subsystem: gtk
tags: [gtk, gtk3, gtk4, stow, gitignore, glib]
requires:
  - "22-01"
provides:
  - "stow/gtk/.config/gtk-3.0/settings.ini"
  - "stow/gtk/.config/gtk-3.0/bookmarks"
  - "stow/gtk/.config/gtk-4.0/settings.ini"
  - ".gitignore theme output exclusion for gtk-dark.css"
  - "scripts/phase22-kde-and-gtk-capture-assert.sh (Section 3)"
affects:
  - "~/.config/gtk-3.0/settings.ini"
  - "~/.config/gtk-3.0/bookmarks"
  - "~/.config/gtk-4.0/settings.ini"
  - ".gitignore"
tech-stack:
  added: []
  patterns: [SAFE-01, per-file-unfolding, scratch-link-severance]
key-files:
  created:
    - stow/gtk/.config/gtk-3.0/settings.ini
    - stow/gtk/.config/gtk-3.0/bookmarks
    - stow/gtk/.config/gtk-4.0/settings.ini
  modified:
    - .gitignore
    - scripts/phase22-kde-and-gtk-capture-assert.sh
key-decisions:
  - "D-08: Adopted GTK-3.0 and GTK-4.0 configurations into stow/gtk/ per-file with parent directories unfolded"
  - "D-09: Enforced unfolded parent directories (~/.config/gtk-3.0 and ~/.config/gtk-4.0) preventing stow directory folding"
  - "D-10: Simulated GLib link severance in scratch fixture; verify acts as watchdog if link is severed"
  - "D-11: Preserved literal file:///home/pera/ URI format in bookmarks"
  - "D-12: Excluded legacy GTK 2.0 configuration files (~/.gtkrc-2.0, ~/.config/gtkrc) from stow"
  - "D-13: Added gtk-dark.css to root .gitignore beside gtk.css under generated theme outputs"
requirements-completed: [KDE-02]
coverage:
  - id: D4
    description: "KDE-02 Adopt GTK-3.0 and GTK-4.0 configuration files per-file into stow/gtk/"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "test -L ~/.config/gtk-3.0/settings.ini && test -L ~/.config/gtk-3.0/bookmarks && test -L ~/.config/gtk-4.0/settings.ini"
        status: pass
    human_judgment: false
  - id: D5
    description: "KDE-02 Enforce unfolded parent directories on live system"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "test -d ~/.config/gtk-3.0 && test ! -L ~/.config/gtk-3.0 && test -d ~/.config/gtk-4.0 && test ! -L ~/.config/gtk-4.0"
        status: pass
    human_judgment: false
  - id: D6
    description: "KDE-02 Add gtk-dark.css to .gitignore and verify ignored status"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "grep -q '^gtk-dark\\.css$' .gitignore && git check-ignore -v stow/gtk/.config/gtk-4.0/gtk-dark.css"
        status: pass
    human_judgment: false
  - id: D7
    description: "KDE-02 Implement Section 3 in assert harness with GLib link severance demonstration"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "./scripts/phase22-kde-and-gtk-capture-assert.sh --section 3"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-09-15T09:05:00Z
---

# Phase 22 Plan 02: GTK Per-File Configuration Capture Summary

Granular GNU Stow package `stow/gtk/` established managing `gtk-3.0/settings.ini`, `gtk-3.0/bookmarks`, and `gtk-4.0/settings.ini` per file with host parent directories kept unfolded (`--no-folding`), `gtk-dark.css` gitignored alongside `gtk.css`, and GLib link severance demonstrated in an isolated scratch fixture.

## Accomplishments
- **GTK Per-File Package Deployment:** Adopted `settings.ini` and `bookmarks` for GTK 3.0 and `settings.ini` for GTK 4.0 using SAFE-01 protocol (`.bak.<epoch>` backups, `--no-folding` dry run, and inode identity matching).
- **Parent Directory Unfolding Enforcement (D-09):** Preserved `~/.config/gtk-3.0` and `~/.config/gtk-4.0` as real directories on the host, preventing generated theme sibling outputs (`gtk.css`, `gtk-dark.css`) from folding into repository tracking.
- **Gitignore Protection (D-13):** Extended `.gitignore` to ignore slash-free `gtk-dark.css` under the generated theme outputs section, verified via `git check-ignore`.
- **Link Severance Simulation (Q6, D-10):** Added Section 3 to `scripts/phase22-kde-and-gtk-capture-assert.sh` proving that Python GLib `GLib.file_set_contents` atomically replaces symlinks with plain files, confirming that `arch/dots-hyprland.sh verify` serves as an active watchdog.

## Self-Check: PASSED
- `stow/gtk/.config/gtk-3.0/{settings.ini,bookmarks}` and `stow/gtk/.config/gtk-4.0/settings.ini` exist in repository.
- Host directories `~/.config/gtk-3.0` and `~/.config/gtk-4.0` are directories and not symlinks.
- `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 3` passes with `FAIL=0 FINDINGS=0`.
- Working tree clean.

## Deviations from Plan
None - plan executed exactly as written.
