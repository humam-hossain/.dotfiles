# Requirements: Quickshell Desktop Shell

**Defined:** 2026-07-25  
**Milestone:** v0.2 Adopt dots-hyprland  
**Core Value:** Keep desktop capability via upstream dots-hyprland + personal overlays — not a from-scratch QML rewrite.

## v0.2 Requirements

Requirements for this milestone only. Each maps to roadmap phases (continuing after v0.1 phases 1–4).

### Ownership & Pin

- [x] **OWN-01**: Operator has a personal GitHub fork of end-4/dots-hyprland with `origin` pointing at the fork and `upstream` pointing at `https://github.com/end-4/dots-hyprland.git`
- [x] **OWN-02**: `.dotfiles` includes a git submodule at `vendor/dots-hyprland` whose URL targets the personal fork and whose commit SHA is pinned in the parent repo
- [x] **OWN-03**: Nested submodules inside dots-hyprland (including shapes / rounded-polygon) initialize successfully via recursive submodule update

### Install Wrapper

- [x] **WRAP-01**: Operator can run a thin `arch/dots-hyprland.sh` (or agreed name) from REPO_ROOT that invokes upstream `./setup` for `install`, `install-deps`, `install-setups`, and `install-files` without reimplementing package lists
- [x] **WRAP-02**: Wrapper defaults to a safe dual-run profile including `--core` and `--skip-hyprland` so personal `hyprland.conf` / hyprlock are not renamed or replaced on first adoption
- [x] **WRAP-03**: Wrapper surfaces a backup gate or explicit reminder before the files step and does not encourage `--skip-backup` on first adoption
- [x] **WRAP-04**: Wrapper accepts additional `./setup` flags via passthrough so operators can override defaults intentionally

### Live Session & Dual-Run

- [x] **LIVE-01**: After install-files, `~/.config/quickshell` is a real installed tree synced from upstream (not a symlink to `.dotfiles/.config/quickshell`)
- [x] **LIVE-02**: Personal Hyprland config (owned by `.dotfiles`) sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV` to the ii venv path and starts the shell with `qs -c ii` (exec-once or equivalent)
- [x] **LIVE-03**: After adoption steps, Waybar (and existing swaync/rofi session pieces as currently configured) still start — dual-run is preserved; no cutover removal this milestone
- [x] **LIVE-04**: Operator can verify the installed illogical-impulse shell is running in the Hyprland session (visible bar/shell chrome from `qs -c ii`)

### Product Retirement

- [x] **RET-01**: After LIVE-04 is satisfied, the in-repo v0.1 `.config/quickshell` product tree is removed from `.dotfiles` so it is no longer shipped
- [x] **RET-02**: `arch/quickshell.sh` is retired (removed or reduced to a deprecation stub that points at the new wrapper) so it is not a second installer

### Documentation

- [ ] **DOC-01**: Documentation describes clone → submodule init (recursive) → wrapper install → personal hypr hooks → dual-run expectations
- [ ] **DOC-02**: Documentation describes the update contract: fetch/merge upstream in the fork/submodule, bump parent pin, re-run setup — and states that `exp-merge` / online cache install are non-primary

## Future Requirements

Deferred beyond v0.2. Tracked but not in this roadmap.

### Customization & parity

- **CUST-01**: Port Waybar ping monitor widget ( consums `127.0.0.1:8765/api/status` ) into ii/Quickshell
- **CUST-02**: Port weather + forecast Waybar modules into ii
- **CUST-03**: Port earthquake alert and other remaining Waybar customs as needed
- **CUST-04**: Machine-specific overlays (monitors DP-1/HDMI-A-2, Asia/Dhaka, paths) as a documented overlay layer on the fork

### Cutover & polish

- **CUT-01**: Remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is accepted
- **CUT-02**: Optional full ii Hyprland Lua entry cutover (only with explicit personal conf migration)
- **POLISH-01**: Wrapper `verify` subcommand (qs binary, config path, submodule SHA)
- **POLISH-02**: FWK-02 / IPC-02 style auto-start and bar-toggle keybind under upstream model
- **POLISH-03**: Re-evaluate open v0.1 debug polish items only if still relevant on stock ii

## Out of Scope

| Feature | Reason |
|---------|--------|
| Reimplement ii package install in `arch/` without `./setup` | Upstream setup is SoT; reimplementation bitrots |
| Waybar custom module ports in v0.2 | Foundation-first; customs need live shell |
| Full Waybar/rofi/swaync cutover in v0.2 | Dual-run intentional until parity |
| Full hyprland.lua session takeover in v0.2 | Protects personal conf; Lua cutover is its own milestone |
| DDC/CI brightness widget / ddcutil polling | iGPU hang post-mortem `issues/2026-07-16_*` |
| Replace hyprlock with QS lock screen | hyprlock kept |
| AI chat, Booru, SongRec, LaTeX, gcloud translate, anti-flashbang, first-run onboarding investment | Explicitly not wanted |
| Continuing hand-rolled local QS as primary product | Retired this milestone |
| Debian/Ubuntu parity for new install path | Arch primary |
| Auto-bump submodule on every parent pull | Breaks reproducibility |
| `exp-merge` / `exp-update` as primary update | Experimental; document only |
| Wrapper verify subcommand | Explicitly not selected for v0.2 (future POLISH-01) |

## Traceability

Which phases cover which requirements. Updated with v0.2 roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| OWN-01 | Phase 5 | Complete |
| OWN-02 | Phase 5 | Complete |
| OWN-03 | Phase 5 | Complete |
| WRAP-01 | Phase 6 | Complete |
| WRAP-02 | Phase 6 | Complete |
| WRAP-03 | Phase 6 | Complete |
| WRAP-04 | Phase 6 | Complete |
| LIVE-01 | Phase 7 | Complete |
| LIVE-02 | Phase 7 | Complete |
| LIVE-03 | Phase 7 | Complete |
| LIVE-04 | Phase 7 | Complete |
| RET-01 | Phase 8 | Complete |
| RET-02 | Phase 8 | Complete |
| DOC-01 | Phase 9 | Pending |
| DOC-02 | Phase 9 | Pending |

**Coverage:**

- v0.2 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-07-25*  
*Last updated: 2026-07-25 after v0.2 roadmap mapping*
