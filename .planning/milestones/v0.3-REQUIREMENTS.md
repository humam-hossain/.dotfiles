# Requirements: Quickshell Desktop Shell

**Defined:** 2026-08-03  
**Milestone:** v0.3 Full ii install  
**Core Value:** Keep desktop capability via upstream dots-hyprland + personal overlays — full session install only after known dispositions for replaced configs.

## v0.3 Requirements

Requirements for this milestone only. Phase numbering continues after v0.2 (last phase **9** → start **10**).

### Impact inventory

- [x] **INV-01**: Operator has a written impact inventory listing every filesystem path and package/sysupdate effect of a full dots-hyprland install **without** `--skip-hyprland`, and separately noting effects of dropping `--core` and `--skip-sysupdate`
- [x] **INV-02**: Inventory compares personal `.config/hypr` (at least `hyprland.conf`, hyprlock, hypridle, hyprpaper, any `hypr/hyprland` content) against upstream `dots/.config/hypr` install behavior (conf → `.old`, hyprland dir sync, hyprland.lua entry, lock/idle auto_backup, custom ignore_existing)
- [x] **INV-03**: Inventory lists non-hypr personal configs that clash if `--core` is dropped (at least fish, kitty, starship, fontconfig, and other `dots/.config` misc targets present on this machine)
- [x] **INV-04**: Inventory records the SAFE_DEFAULTS install behavior as Phase 10 found it — a frozen record of what that phase captured, not a claim about what the wrapper does now (Phase 16 retired the profile; the Phase 10 record stands)

### Disposition decisions

- [x] **DISP-01**: Every high-risk inventory row has an explicit disposition: keep-personal / migrate-to-hypr-custom / accept-upstream / merge / defer — with short rationale
- [x] **DISP-02**: Disposition set includes staged flag choices: whether full adopt drops `--skip-hyprland` only, also drops `--core`, and/or allows sysupdate (not assumed all three)
- [x] **DISP-03**: Disposition for dual-run chrome (Waybar/rofi/swaync exec-once) defaults to **keep** unless explicitly accepted otherwise
- [x] **DISP-04**: Disposition covers hyprlock/hypridle vs product choice to keep hyprlock (no QS lock screen investment)

### Personal overlay migration

- [x] **OVL-01**: Personal must-keeps selected for migrate (monitors, workspaces, env, exec-once, keybinds, rules as applicable) are expressed as `hypr/custom` Lua overlays compatible with ii `hyprland.lua` require contract
- [x] **OVL-02**: Overlay preparation is completed (or explicitly checklist-gated) **before** the first live full hypr files install that would rely on those must-keeps
- [x] **OVL-03**: Repo vs live vs fork SoT policy for hypr/custom after cutover is written and followed for any committed overlays

### Full-install path (wrapper)

- [x] **FULL-01**: The wrapper's only install path is the full one — no subcommand injects `--core`, `--skip-hyprland` or `--skip-sysupdate`, and there is no profile to choose
- [x] **FULL-02**: A bare `./arch/dots-hyprland.sh install` / `install-files` **is** the full behavior; `--full` survives only as an announced no-op alias
- [x] **FULL-04**: The install path supports `--dry-run`, printing the exact `./setup` argv so the operator can verify it before any mutation

### Live adopt & verify

- [x] **ADOPT-01**: Live full install is executed only after INV-* and DISP-* are satisfied (process gate)
- [x] **ADOPT-02**: After full hypr adopt, Hyprland session loads via ii Lua entry (`hyprland.lua` / hyprland tree) rather than the pre-adopt personal `hyprland.conf` as primary
- [x] **ADOPT-03**: After adopt, operator-verified: monitors/layout per disposition, and the ii shell (`qs -c ii`) runs

### Documentation

- [x] **DOC-03**: Playbook documents the single full-only install path, the inventory→disposition→adopt sequence, and the update and recovery contracts
- [x] **DOC-04**: Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy from OVL-03

## Future Requirements

Deferred beyond v0.3.

### Customization & parity (from v0.2)

- **CUST-01**: Port Waybar ping monitor widget (`127.0.0.1:8765/api/status`) into ii/Quickshell
- **CUST-02**: Port weather + forecast Waybar modules into ii
- **CUST-03**: Port earthquake alert and other remaining Waybar customs as needed
- **CUST-04**: Machine-specific overlays beyond hypr session (if not fully covered by OVL-*) as documented fork layer

### Cutover & polish

- **CUT-01**: Remove Waybar/rofi/swaync from Hyprland startup once parity is accepted — **[superseded by Phase 16]** already delivered by the Phase 11 D-11 accept-remove decision and the Phase 14 adopt; stays outside the coverage count
- **CUT-02**: (partially in v0.3 as full hypr adopt) residual Lua/session polish after first full adopt
- **POLISH-01**: Wrapper `verify` subcommand (qs binary, config path, submodule SHA)
- **POLISH-02**: FWK-02 / IPC-02 style auto-start and bar-toggle keybind under upstream model
- **POLISH-03**: Re-evaluate open v0.1 debug polish items only if still relevant on stock ii

## Out of Scope

| Feature | Reason |
|---------|--------|
| Blind full install without inventory/dispositions | Explicit anti-goal of this milestone |
| Waybar custom module ports (CUST-01..03) | Separate parity track; Waybar, rofi and swaync were accept-removed from the session at the Phase 14 adopt, so the ports are parity work with no v0.3 deliverable |
| Reimplement ii package install in `arch/` without `./setup` | Upstream setup remains SoT |
| DDC/CI brightness / ddcutil polling | iGPU hang post-mortem |
| Replace hyprlock with Quickshell lock screen | Product choice unchanged |
| AI chat, Booru, SongRec, LaTeX, gcloud translate, anti-flashbang onboarding investment | Not wanted |
| Debian/Ubuntu parity | Arch primary |
| Auto-bump submodule on every parent pull | Breaks reproducibility |
| Upstream `./setup uninstall` as rollback | Cascade risk; wrapper safe paths only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-01 | Phase 10 | Complete |
| INV-02 | Phase 10 | Complete |
| INV-03 | Phase 10 | Complete |
| INV-04 | Phase 10 | Complete |
| DISP-01 | Phase 11 | Complete |
| DISP-02 | Phase 11 | Complete |
| DISP-03 | Phase 11 | Complete |
| DISP-04 | Phase 11 | Complete |
| FULL-01 | Phase 16 | Complete |
| FULL-02 | Phase 16 | Complete |
| FULL-04 | Phase 16 | Complete |
| OVL-01 | Phase 13 | Complete |
| OVL-02 | Phase 13 | Complete |
| OVL-03 | Phase 13 | Complete |
| ADOPT-01 | Phase 14 | Complete |
| ADOPT-02 | Phase 14 | Complete |
| ADOPT-03 | Phase 16 | Complete |
| DOC-03 | Phase 16 | Complete |
| DOC-04 | Phase 15 | Complete |

**Coverage:**

- v0.3 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

Phase 16 retired three rows together with the machinery each described — the install-time
snapshot prompt, the post-install package re-marking pass, and the rollback guidance that
depended on both — dropping the v0.3 count from 22 to 19. The retired identifiers are
listed in `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md`
so no deleted ID survives here as an orphan. `INV-04` was rewritten but stays mapped to Phase 10, because it records what
Phase 10 captured and `scripts/phase10-inventory-assert.sh` still verifies that frozen
record (D-26 over D-27, D-39).

---
*Requirements defined: 2026-08-03*  
*Last updated: 2026-09-08 after the Phase 16 safe-profile retirement (D-26, D-27)*
