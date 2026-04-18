# FAILURES.md — Runtime Failure Inventory

**Generated:** 2026-04-18T06:08:48Z
**Status:** Discovered (requires manual confirmation)

## Environment

OS: Linux 6.19.11-arch1-1 x86_64
Neovim: NVIM v0.12.1
Tools: jq: jq-1.8.1, git: git version 2.53.0

## Failure Inventory

| ID | Description | Owner | Status | Repro Steps | Provenance |
|----|-------------|-------|--------|--------------|-------------|
| BUG-001 | neo-tree plugin failed to load | plugin | Discovered | See provenance source for details | health |
| BUG-002 | --- TODO: LSP client setup - vim.lsp.config(), mason, diagnostics --- | plugins/lsp.lua | Discovered | See provenance source for details | todo |
| BUG-003 | --- TODO: UI enhancements - snacks.nvim dashboard/notifier/picker --- | plugins/snacks | Discovered | See provenance source for details | todo |
| BUG-004 | --- TODO: Statusline - lualine, tmux guard --- | plugins/lualine | Discovered | See provenance source for details | todo |
| BUG-005 | --- TODO: Syntax parsing - treesitter install/update --- | plugins/treesitter.lua | Discovered | See provenance source for details | todo |
| BUG-006 | --- TODO: Indent textobjects - vim-indent-object --- | plugins/vim-indent-object | Discovered | See provenance source for details | todo |
| BUG-007 | --- TODO: Git integration - gitsigns, fugitive --- | plugins/git.lua | Discovered | See provenance source for details | todo |
| BUG-008 | --- TODO: Format-on-save dispatcher - conform.nvim --- | plugins/conform.lua | Discovered | See provenance source for details | todo |
| BUG-009 | --- TODO: Colorscheme - catppuccin, highlights --- | plugins/colortheme | Discovered | See provenance source for details | todo |
| BUG-010 | --- TODO: Completion engine - blink.cmp config --- | plugins/blink-cmp.lua | Discovered | See provenance source for details | todo |
| BUG-011 | --- TODO: Project scoping - project.nvim --- | plugins/project | Discovered | See provenance source for details | todo |
| BUG-012 | --- TODO: Folding UX - nvim-ufo, virtual text --- | plugins/ufo.lua | Discovered | See provenance source for details | todo |
| BUG-013 | --- TODO: Buffer tabs - bufferline.nvim --- | plugins/bufferline | Discovered | See provenance source for details | todo |
| BUG-014 | --- TODO: Misc plugins - which-key, autopairs, todo-comments --- | plugins/misc | Discovered | See provenance source for details | todo |
| BUG-015 | --- TODO: Editor defaults - cursor, fold, search, clipboard, etc. --- | core/options.lua | Discovered | See provenance source for details | todo |
| BUG-016 | --- TODO: Lazy keymap compilation for plugin specs --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-017 | --- TODO: Declarative keymap registry - id, lhs, mode, desc, domain, scope --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-018 | --- TODO: Which-key group registration --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-019 | 		vim.notify("[keymaps.whichkey] which-key not loaded", vim.log.levels.DEBUG) | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-020 | --- TODO: Global mapping application at startup --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-021 | --- TODO: Buffer-local mappings on LSP attach --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-022 | --- TODO: Global keymaps - smart quit, save/format, tmux navigation --- | core/keymaps/ | Discovered | See provenance source for details | todo |
| BUG-023 | --- TODO: Health snapshot for validation harness --- | core/health.lua | Discovered | See provenance source for details | todo |
| BUG-024 | --- TODO: External file open via vim.ui.open() - cross-platform --- | unknown | Discovered | See provenance source for details | todo |
