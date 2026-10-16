## Deferred Items

- `~/.zshrc` is a regular file, not a stow symlink, so `./arch/dots-hyprland.sh verify --strict` reports `[FAIL] not a symlink: /home/pera/.zshrc — recover with: cd stow && stow -t ~ zsh`
  status: open
  **What:** Host state outside the Phase 54.4 scope. The file was rewritten on the host at 2026-10-16 00:55, before this phase ran. It is present at the phase base, so plan 54.4-01 did not cause it. The 54.4 harness reports it as a FINDING (outside the quickshell scope) instead of a FAIL. Recovery is the user's call: back up the current `~/.zshrc`, then run `cd stow && stow -t ~ zsh`.
  **Found during:** 54.4-01 Task 2 (strict verify baseline)
