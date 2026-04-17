# Project Research: Pitfalls for v1.1 Bug-Fix Milestone

**Project:** Cross-Platform Neovim Dotfiles
**Milestone:** v1.1 Neovim Setup Bug Fixes
**Researched:** 2026-04-17

## Common Mistakes For This Milestone

### Mistake 1: Treat every warning as config bug

- Risk: chase machine-local tool gaps instead of real setup defects
- Prevention: classify `:checkhealth` findings into config, optional tool, environment, upstream
- Best phase: health cleanup

### Mistake 2: Add scripts before understanding health coverage

- Risk: duplicate validators and maintenance burden
- Prevention: make `:checkhealth` primary, add scripts only for blind spots
- Best phase: validation expansion

### Mistake 3: Fix symptoms without repro cases

- Risk: bug returns after unrelated refactor
- Prevention: each bug class gets reproducible command, keypath, or documented interaction flow
- Best phase: failure inventory and verification

### Mistake 4: Overreact with plugin churn

- Risk: new regressions from replacing plugins instead of fixing config
- Prevention: replace plugin only when root cause is proven and fix cost exceeds value
- Best phase: plugin hardening

### Mistake 5: Ignore cross-platform guards while fixing Linux-local bugs

- Risk: Linux fix breaks Windows or non-tmux usage
- Prevention: validate guards and README behavior after each fix touching shell, path, UI, or tool logic
- Best phase: every execution phase

---
*Research completed: 2026-04-17*
