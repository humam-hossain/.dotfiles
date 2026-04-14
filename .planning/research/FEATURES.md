# Feature Research

**Domain:** Cross-platform Neovim configuration modernization
**Researched:** 2026-04-14
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Stable startup on every supported OS | Broken startup makes config unusable | HIGH | Includes bootstrap, plugin loading, missing-binary behavior |
| Predictable buffer/window/tab lifecycle | Core editing must not unexpectedly quit editor | HIGH | Directly tied to current smart-quit bug |
| Centralized keymaps with discoverable grouping | Advanced configs become unmaintainable otherwise | MEDIUM | Single source of truth should drive user-facing mappings |
| Modern LSP/completion/formatting defaults | Users expect code intelligence to work out of the box | MEDIUM | Needs alignment with Neovim 0.11 ecosystem direction |
| Repeatable health checks / smoke tests | Otherwise refactors regress silently | MEDIUM | Headless validation is the minimum acceptable floor |
| Cross-platform open/path/shell safety | Linux-only assumptions break Windows immediately | MEDIUM | Replace shell-specific shortcuts with Neovim APIs where possible |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Aggressive plugin audit with explicit keep/replace/remove decisions | Produces a cleaner config than cargo-cult starter repos | HIGH | Important because user explicitly wants cleanup, not preservation |
| Structured portability layer | Makes one repo practical across Linux + Windows | MEDIUM | Could live in utility module or guarded platform helpers |
| Central command/keymap taxonomy | Easier to extend and review than plugin-local scattered maps | MEDIUM | Strong maintainability win |
| Regression-prevention workflow in repo docs/scripts | Makes future changes safer, not just today’s cleanup | MEDIUM | High leverage after initial cleanup |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Keep every existing plugin “just in case” | Fear of losing capability | Preserves dead weight and bug surface | Audit each plugin explicitly |
| OS-specific forks of the config | Quick path to get things working fast | Long-term maintenance split and feature drift | One repo with guarded helpers |
| More UI plugins before stabilizing core behavior | Feels like progress | Adds noise before reliability is fixed | Reliability + keymap + portability first |
| Deep custom shell command bindings everywhere | Powerful on one machine | Fragile across platforms and terminals | Wrap external actions behind platform-aware helpers |

## Feature Dependencies

```text
Cross-platform compatibility
    └──requires──> runtime helper layer
                       └──requires──> command/path/open abstraction

Centralized keymaps
    └──requires──> command taxonomy
                       └──enhances──> plugin audit

Plugin modernization
    └──requires──> startup and health validation

Buffer/window lifecycle fixes
    └──conflicts──> scattered quit/save behavior
```

### Dependency Notes

- **Cross-platform compatibility requires runtime helpers:** raw shell commands and path assumptions need one abstraction point
- **Centralized keymaps require command taxonomy:** moving mappings to one file is not enough; names and grouping must be coherent
- **Plugin modernization requires validation:** without smoke tests, replacements are guesswork
- **Buffer lifecycle fixes conflict with scattered save/quit logic:** current behavior must be simplified before it becomes reliable

## MVP Definition

### Launch With (v1)

- [ ] Startup works cleanly on Arch Linux, Debian/Ubuntu, and Windows
- [ ] Save/quit and buffer navigation behavior is predictable and bug-free
- [ ] All custom keymaps live in one centralized file or registry
- [ ] Plugin audit completed with obsolete/problematic plugins removed or replaced
- [ ] Health-check/smoke-test workflow documented and runnable
- [ ] Core editor workflows (LSP, completion, formatting, tree/search/git) remain solid after cleanup

### Add After Validation (v1.x)

- [ ] Extra UI polish after core ergonomics prove stable
- [ ] More performance tuning after plugin set is finalized
- [ ] Optional machine-specific quality-of-life integrations after portability layer stabilizes

### Future Consideration (v2+)

- [ ] Full CI automation for Neovim smoke testing across OSes
- [ ] Separate optional plugin profiles by machine role if one config becomes too broad

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Fix save/quit buffer bug | HIGH | MEDIUM | P1 |
| Centralize keymaps | HIGH | MEDIUM | P1 |
| Cross-platform compatibility layer | HIGH | HIGH | P1 |
| Plugin audit and replacement | HIGH | HIGH | P1 |
| Health-check automation | HIGH | MEDIUM | P1 |
| UI polish/theme cleanup | MEDIUM | LOW/MEDIUM | P2 |
| Startup micro-optimization | MEDIUM | MEDIUM | P2 |

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Plugin management | LazyVim-style modular lazy specs | Hand-rolled starter repos | Keep modular lazy specs, but slimmer and more intentional |
| Keymaps | Central grouped keymap files | Plugin-local maps everywhere | Centralize all custom mappings |
| Portability | Often Linux/macOS first | Often single-machine assumptions | Treat Windows as first-class target from start |
| Validation | Occasional `:checkhealth` only | None | Add documented smoke-test workflow |

## Sources

- Official Neovim docs
- Official plugin repos for `lazy.nvim`, `mason.nvim`, `mason-lspconfig.nvim`, `blink.cmp`, `neo-tree.nvim`, `noice.nvim`
- Existing codebase map in `.planning/codebase/`

---
*Feature research for: cross-platform Neovim configuration modernization*
*Researched: 2026-04-14*
