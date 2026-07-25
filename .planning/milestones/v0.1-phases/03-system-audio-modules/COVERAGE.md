# API Coverage — Phase 03 system-audio-modules

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
>
> **Detector note:** phase docs mention internal QML “Resource API” / BarContent
> assignment API surfaces. Those are local Quickshell/QML contracts, not an
> external SaaS HTTP/SDK integration. This matrix records that decision so
> `api-coverage.verify-pre` can seal.

| capability | decision | reason |
|---|---|---|
| external SaaS / cloud HTTP APIs | OPT-OUT | Desktop shell phase only; no third-party network API in scope |
| third-party media platform SDK (Spotify, YouTube, etc.) | OPT-OUT | Audio is local Pipewire session, not a cloud media platform |
| host resource metrics (CPU / RAM / disk) | INTEGRATE | Local proc/process/`df` polling for bar resource modules |
| Pipewire sink volume, mute, and ceiling | INTEGRATE | Local session audio via Quickshell Pipewire service |
| Pipewire source (mic) input gain | INTEGRATE | Local session source volume binding for mic indicator |
| pavucontrol / volume mixer launch | INTEGRATE | Local process launch for mixer UI (middle/right click) |
