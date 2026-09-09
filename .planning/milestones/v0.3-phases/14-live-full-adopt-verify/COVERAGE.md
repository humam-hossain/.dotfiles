# API Coverage — Phase 14 (live full adopt & verify)

No external API integration: this phase produces two local bash assert scripts, one operator
runbook, one recorded-facts fixture, a two-line deletion from an existing bash array, and a
live-to-repo `.config` archive commit. Its only "integration" surfaces are local process
tools already installed on this machine (`hyprctl`, `busctl`, `git`, `stow`, `rsync`,
`script(1)`) and the repo's own `arch/dots-hyprland.sh` wrapper — none of which is an
external API, SDK, or hosted service. The `arch/dots-hyprland.sh install --full` run the
operator performs installs packages chosen by the pinned `vendor/dots-hyprland` submodule
(`1a9ffb78f0c272a45f82342587dc3bec72762233`), not by this phase.

Detector result at plan time: `{"detected":false,"signals":[]}`.
