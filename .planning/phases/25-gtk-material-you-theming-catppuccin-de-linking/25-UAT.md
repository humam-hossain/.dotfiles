---
status: diagnosed
phase: 25-gtk-material-you-theming-catppuccin-de-linking
source:
  - .planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-01-SUMMARY.md
  - .planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-02-SUMMARY.md
  - .planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-03-SUMMARY.md
started: 2026-09-16T22:30:00+06:00
updated: 2026-09-16T23:34:00+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Legacy Catppuccin De-linking and GTK 4 Directory Structure
expected: ~/.config/gtk-4.0/ is an unfolded regular directory with no legacy root-owned Catppuccin symlinks (assets, gtk.css, gtk-dark.css pointing to /usr/share/themes/ are removed), and settings.ini remains cleanly linked to Stow.
result: pass

### 2. GTK 3 and GTK 4 Settings Alignment
expected: ~/.config/gtk-3.0/settings.ini and ~/.config/gtk-4.0/settings.ini declare gtk-theme-name=adw-gtk3-dark, gtk-application-prefer-dark-theme=1, gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500, and Bibata-Modern-Classic cursor (size 24) with zero Catppuccin theme references.
result: pass

### 3. GNOME Desktop Interface GSettings Synchronization
expected: gsettings get org.gnome.desktop.interface color-scheme returns 'prefer-dark' and gsettings get org.gnome.desktop.interface gtk-theme returns 'adw-gtk3-dark', with icon theme Tela-circle-dracula-dark and cursor Bibata-Modern-Classic.
result: pass

### 4. Dynamic Material You GTK CSS Generation
expected: ~/.config/gtk-3.0/gtk.css and ~/.config/gtk-4.0/gtk.css exist as regular non-empty files containing Material You variables and dark scheme rules generated from the active desktop wallpaper (/home/pera/Pictures/55192173787_b8322b1190_o.jpg), ignored by git with zero repository working-tree churn.
result: pass

### 5. Visual GTK Application Theming and Accent Rendering
expected: Launching a GTK 3 or GTK 4 application (e.g. nautilus, pavucontrol, or file chooser) displays dark Adwaita styling with wallpaper-derived Material You accents and correct typography without theme fallback warnings or errors.
result: issue
reported: "no i don't think so. still catppuccin color pink"
severity: cosmetic

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-25-5
  truth: "Launching a GTK 3 or GTK 4 application displays dark Adwaita styling with wallpaper-derived Material You accents and correct typography without theme fallback warnings or errors."
  status: failed
  reason: "User reported: no i don't think so. still catppuccin color pink"
  severity: cosmetic
  test: 5
  root_cause: "Observed pink accents are from two sources: (1) Default shortcuts launch Dolphin and Pavucontrol-Qt, which are Qt 6/KDE applications reading ~/.config/kdeglobals (LastUsedCustomAccentColor=184,117,220 and DecorationFocus=#cdb9fb - mauve/pink); Qt harmonization is scoped to Phase 26 (QT-01..QT-03). (2) In GTK apps like Nautilus, UI widgets render cyan (#82d3e1), but the active Tela-circle-dracula-dark icon theme hardcodes Dracula pink/purple (#bd93f9) on folder icon tabs. Additionally, ~/.config/matugen/templates/gtk-4.0/gtk.css uses :insensitive instead of :disabled on line 312."
  artifacts:
    - path: "~/.config/kdeglobals"
      issue: "Qt/KDE apps read unharmonized pink/mauve accent (Phase 26 scope)"
    - path: "~/.config/matugen/templates/gtk-4.0/gtk.css"
      issue: "Line 312 uses GTK 3 :insensitive instead of GTK 4 :disabled"
    - path: "stow/gtk/.config/gtk-3.0/settings.ini"
      issue: "Uses Tela-circle-dracula-dark icon theme with pink folder accents"
  missing:
    - "Fix GTK 4 matugen template line 312 :insensitive -> :disabled pseudo-class"
    - "Differentiate GTK 3/4 app testing (nautilus UI controls) from Qt apps (dolphin in Phase 26)"
  debug_session: ".planning/debug/DEBUG-gtk-visual-theming-pink-accent.md"
