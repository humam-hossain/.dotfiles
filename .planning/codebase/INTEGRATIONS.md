# External Integrations

**Analysis Date:** 2026-04-14

## APIs & External Services

**Plugin Sources:**
- GitHub - Lazy bootstrap clones `folke/lazy.nvim` from `https://github.com/folke/lazy.nvim.git` in `.config/nvim/init.lua`
  - SDK/Client: external `git` CLI
  - Auth: none required for public clone
  - Endpoints used: GitHub git remote during first bootstrap

**Reference Content:**
- YouTube - Documentation links only in `.config/nvim/README.md`
  - Integration method: human reference, not runtime code path
  - Auth: none

## Data Storage

**Databases:**
- None found

**File Storage:**
- Local filesystem - Core integration surface for editor buffers and tree navigation
  - Accessed by Neovim itself plus plugins like `neo-tree`
  - User-triggered open-in-app flow via `xdg-open` in `.config/nvim/lua/core/keymaps.lua` and `.config/nvim/lua/plugins/neotree.lua`

**Caching:**
- None explicitly configured in repo

## Authentication & Identity

**Auth Provider:**
- None found

**OAuth Integrations:**
- None found

## Monitoring & Observability

**Error Tracking:**
- None found

**Analytics:**
- None found

**Logs:**
- Neovim message area / plugin UIs only
  - `folke/noice.nvim` and `rcarriga/nvim-notify` provide local UI presentation in `.config/nvim/lua/plugins/notify.lua`

## CI/CD & Deployment

**Hosting:**
- None; repo stores local dotfiles

**CI Pipeline:**
- None found under `.config/nvim` scope

## Environment Configuration

**Development:**
- Requires local Neovim runtime
- Depends on internet access during initial plugin/tool install via `git`, `lazy.nvim`, Mason, and Treesitter parser downloads
- Depends on local shell utilities like `rg` for `fzf-lua` live grep and `xdg-open` for open-in-default-app mappings

**Staging:**
- None

**Production:**
- Same as development; config runs on user machine

## Webhooks & Callbacks

**Incoming:**
- LSP and Neovim autocommand callbacks only; no network webhook endpoints

**Outgoing:**
- `git clone` during plugin bootstrap
- Mason/tool and Treesitter parser downloads implied by configured plugins, though exact transport code lives inside plugin internals rather than this repo

---

*Integration audit: 2026-04-14*
*Update when adding/removing external services*
