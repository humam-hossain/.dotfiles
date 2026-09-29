# Debug Session: Network Popup Styling, Typography, and Contrast

## Symptoms
User reported:
- Left column font size is too small.
- DNS nameservers should be split across multiple lines (e.g. "DNS Server 1", "DNS Server 2").
- Link speed needs wrapping or two lines so it doesn't get clipped.
- Remove live bandwidth activity progress bars (unnecessary/distracting; session totals are good).
- Right column ping cards: increase font size of IP address (e.g. 8.8.8.8).
- Quality status tags (normal, critical): text inside has opacity and is hard to read; text should be fully white with high contrast.
- Pulsing animation is missing for critical/alert state.

## Root Cause
1. `NetworkPingPopup.qml`: `NetworkDetailRow` sets `font.pixelSize: Appearance.font.pixelSize.smaller`, which is ~10-11px, making row details small and hard to read.
2. `DNS Nameservers` row displays `NetworkUsage.dnsServers` directly as a single comma-separated string with `elide: Text.ElideRight`. Multiple IPs overflow or get clipped.
3. `Link Speed` row is restricted to a single line with `elide: Text.ElideRight` instead of wrapping cleanly if long.
4. `StyledProgressBar` elements exist under Rx/Tx sections in `NetworkPingPopup.qml` which take up vertical space and add unnecessary visual clutter.
5. In `PingDiagnosticCard`, `ipText` has `font.pixelSize: Appearance.font.pixelSize.smallest` in an 18px badge; increasing badge height and font size improves readability.
6. The status badge `Rectangle` has `opacity: 0.2`, which Qt Quick cascades to its children, making `StyledText` 80% transparent. Background should use `Qt.rgba()` or `Qt.alpha()` instead of setting parent opacity, and text should use `#FFFFFF`.
7. Neither `NetworkPingPill.qml` nor `NetworkPingPopup.qml` has a breathing pulse animation on critical status or offline alerts.

## Fix Direction
1. In `NetworkPingPopup.qml`:
   - Increase font sizes in `NetworkDetailRow` to `Appearance.font.pixelSize.small`.
   - Parse `NetworkUsage.dnsServers` and render separate rows for each DNS server (e.g. "DNS Server 1", "DNS Server 2").
   - Allow Link Speed to wrap or format cleanly.
   - Remove the `StyledProgressBar` components from the Rx and Tx sections.
   - Increase IP address text size in `PingDiagnosticCard`.
   - Fix status badge pill background styling so text is fully opaque pure white (`#FFFFFF`) with 100% opacity, while only the badge background has low opacity.
   - Add critical pulse animation to ping pill and popup cards when latency/target is critical or offline.
