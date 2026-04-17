# Project Research: Features for v1.1 Bug-Fix Milestone

**Project:** Cross-Platform Neovim Dotfiles
**Milestone:** v1.1 Neovim Setup Bug Fixes
**Researched:** 2026-04-17

## Runtime Stability

**Table stakes:**
- Keymaps execute without Lua/runtime errors
- High-use plugin surfaces load and respond without breaking editor flow
- Config does not crash Neovim during common editing workflows

**Differentiators:**
- Fast repro path from user report to script or documented manual check
- Bugs classified by source: keymap, plugin config, tool/env, upstream plugin

## Health Quality

**Table stakes:**
- `:checkhealth` shows no config-caused `ERROR:` entries
- Actionable warnings are either fixed or documented with clear remediation
- Health output distinguishes optional missing tools from real config breakage

**Differentiators:**
- Repo-local helpers aggregate likely problem areas before user manually hunts through sections
- Health guidance points back to known rollout/validator commands

## Validation Coverage

**Table stakes:**
- Maintainer can run repeatable validation before and after fixes
- Headless checks verify startup, plugin load, and critical config surfaces
- Validation artifacts are easy to inspect when a failure happens

**Differentiators:**
- Scripts cover runtime cases `:checkhealth` cannot validate, such as invoking selected keymaps or reproducing crash-prone flows
- Validation commands are safe for daily use before pushing dotfiles to another machine

## Anti-Features

- Feature expansion unrelated to stability
- Broad plugin churn without evidence
- Health cleanup that hides warnings instead of classifying or fixing them

---
*Research completed: 2026-04-17*
