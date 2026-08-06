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
- [x] **INV-04**: Inventory records current SAFE_DEFAULTS behavior and that safe dual-run install remains available after this milestone

### Disposition decisions

- [ ] **DISP-01**: Every high-risk inventory row has an explicit disposition: keep-personal / migrate-to-hypr-custom / accept-upstream / merge / defer — with short rationale
- [ ] **DISP-02**: Disposition set includes staged flag choices: whether full adopt drops `--skip-hyprland` only, also drops `--core`, and/or allows sysupdate (not assumed all three)
- [ ] **DISP-03**: Disposition for dual-run chrome (Waybar/rofi/swaync exec-once) defaults to **keep** unless explicitly accepted otherwise
- [ ] **DISP-04**: Disposition covers hyprlock/hypridle vs product choice to keep hyprlock (no QS lock screen investment)

### Personal overlay migration

- [ ] **OVL-01**: Personal must-keeps selected for migrate (monitors, workspaces, env, exec-once, keybinds, rules as applicable) are expressed as `hypr/custom` Lua overlays compatible with ii `hyprland.lua` require contract
- [ ] **OVL-02**: Overlay preparation is completed (or explicitly checklist-gated) **before** the first live full hypr files install that would rely on those must-keeps
- [ ] **OVL-03**: Repo vs live vs fork SoT policy for hypr/custom after cutover is written and followed for any committed overlays

### Full-install path (wrapper)

- [ ] **FULL-01**: Operator can invoke a **documented explicit opt-in** full-install path (wrapper flag/profile or equivalent) that does not inject `--skip-hyprland` (and applies other flag drops only per DISP-02)
- [ ] **FULL-02**: Default `./arch/dots-hyprland.sh install` / `install-files` **still** injects SAFE_DEFAULTS (`--core --skip-hyprland --skip-sysupdate`) — full is never accidental
- [ ] **FULL-03**: Full path retains backup gate behavior and continues to refuse bare `--skip-backup` without explicit allow override
- [ ] **FULL-04**: Full path supports `--dry-run` showing argv **without** unwanted SAFE_DEFAULTS injection so operator can verify before mutation
- [ ] **FULL-05**: After full install/deps, PROTECT_EXPLICIT re-mark (or equivalent protect) still runs so personal stack packages are not left only asdeps

### Live adopt & verify

- [ ] **ADOPT-01**: Live full install is executed only after INV-* and DISP-* are satisfied (process gate)
- [ ] **ADOPT-02**: After full hypr adopt, Hyprland session loads via ii Lua entry (`hyprland.lua` / hyprland tree) rather than the pre-adopt personal `hyprland.conf` as primary
- [ ] **ADOPT-03**: After adopt, operator-verified: monitors/layout per disposition, shell chrome (`qs -c ii`) runs, and dual-run policy matches DISP-03
- [ ] **ADOPT-04**: Rollback guidance exists that does **not** use upstream `./setup uninstall` (backup restore and/or wrapper safe uninstall/protect only)

### Documentation

- [ ] **DOC-03**: Playbook documents **safe vs full** install profiles, inventory→disposition→adopt sequence, and flag axes (`skip-hyprland` / `core` / `sysupdate`)
- [ ] **DOC-04**: Playbook documents hypr/custom overlay expectations and repo/live/fork SoT policy from OVL-03

## Future Requirements

Deferred beyond v0.3.

### Customization & parity (from v0.2)

- **CUST-01**: Port Waybar ping monitor widget (`127.0.0.1:8765/api/status`) into ii/Quickshell
- **CUST-02**: Port weather + forecast Waybar modules into ii
- **CUST-03**: Port earthquake alert and other remaining Waybar customs as needed
- **CUST-04**: Machine-specific overlays beyond hypr session (if not fully covered by OVL-*) as documented fork layer

### Cutover & polish

- **CUT-01**: Remove Waybar/rofi/swaync from Hyprland startup once parity is accepted
- **CUT-02**: (partially in v0.3 as full hypr adopt) residual Lua/session polish after first full adopt
- **POLISH-01**: Wrapper `verify` subcommand (qs binary, config path, submodule SHA)
- **POLISH-02**: FWK-02 / IPC-02 style auto-start and bar-toggle keybind under upstream model
- **POLISH-03**: Re-evaluate open v0.1 debug polish items only if still relevant on stock ii

## Out of Scope

| Feature | Reason |
|---------|--------|
| Blind full install without inventory/dispositions | Explicit anti-goal of this milestone |
| Waybar custom module ports (CUST-01..03) | Separate parity track; dual-run remains valid |
| Removing Waybar/rofi/swaync by default (CUT-01) | Only if DISP-03 explicitly accepts; default keep |
| Reimplement ii package install in `arch/` without `./setup` | Upstream setup remains SoT |
| DDC/CI brightness / ddcutil polling | iGPU hang post-mortem |
| Replace hyprlock with Quickshell lock screen | Product choice unchanged |
| AI chat, Booru, SongRec, LaTeX, gcloud translate, anti-flashbang onboarding investment | Not wanted |
| Debian/Ubuntu parity | Arch primary |
| Auto-bump submodule on every parent pull | Breaks reproducibility |
| Upstream `./setup uninstall` as rollback | Cascade risk; wrapper safe paths only |
| Making full profile the default wrapper behavior | Safe defaults remain default |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-01 | Phase 10 | Complete |
| INV-02 | Phase 10 | Complete |
| INV-03 | Phase 10 | Complete |
| INV-04 | Phase 10 | Complete |
| DISP-01 | Phase 11 | Pending |
| DISP-02 | Phase 11 | Pending |
| DISP-03 | Phase 11 | Pending |
| DISP-04 | Phase 11 | Pending |
| FULL-01 | Phase 12 | Pending |
| FULL-02 | Phase 12 | Pending |
| FULL-03 | Phase 12 | Pending |
| FULL-04 | Phase 12 | Pending |
| FULL-05 | Phase 12 | Pending |
| OVL-01 | Phase 13 | Pending |
| OVL-02 | Phase 13 | Pending |
| OVL-03 | Phase 13 | Pending |
| ADOPT-01 | Phase 14 | Pending |
| ADOPT-02 | Phase 14 | Pending |
| ADOPT-03 | Phase 14 | Pending |
| ADOPT-04 | Phase 14 | Pending |
| DOC-03 | Phase 15 | Pending |
| DOC-04 | Phase 15 | Pending |

**Coverage:**

- v0.3 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-03*  
*Last updated: 2026-08-03 after v0.3 roadmap mapping*
