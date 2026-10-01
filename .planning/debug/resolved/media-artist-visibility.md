---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: Media Artist Visibility & Elision Order

## Status
Diagnosed

## Gap
G-48-2: Artist is always visible in the media pill; long track titles are elided first while preserving artist display, with adaptive fallback for narrow screens.

## Symptoms Reported
- When playing media with long track titles (e.g. YouTube video "How to Solder TINY SMD Components (3 Methods That Actually Work)" by "Max Imagination"), the artist is not visible on the top bar media pill.
- User expected the artist to always be shown, with the track title being the element that gets shortened/elided when maximum width is reached.
- On narrow screens, responsive threshold handling should define how narrow screens gracefully handle the layout without overflowing or crowding the bar.

## Root Cause Analysis
1. **Single String Concatenation & Right Elision:**
   In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml` (lines 85-94), title and artist are formatted into a single string inside one `StyledText` element:
   ```javascript
   text: {
       const escapedTitle = StringUtils.escapeHtml(cleanedTitle);
       const artist = activePlayer?.trackArtist;
       if (!artist) {
           return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span>`;
       }
       const escapedArtist = StringUtils.escapeHtml(artist);
       return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span><span style="color: ${Appearance.colors.colSubtext};"> • ${escapedArtist}</span>`;
   }
   ```
   The `StyledText` element sets `elide: Text.ElideRight` and `Layout.fillWidth: true`.
   Because the track title is rendered first and `Text.ElideRight` elides from the end (right side) of the text block, any title that exceeds the available space pushes the trailing ` • <artist>` off the right edge. As a result, the artist is elided first, making it invisible to the user.

2. **Narrow Screen Invariant:**
   In `BarContent.qml`, responsive sizing clamps `mediaLoader` width based on screen width:
   - Full screen: `[220px, 450px]` based on `screen.width * 0.12`
   - Shortened screen (`useShortenedForm === 1`, screen <= 1200px): `[140px, 180px]` based on `screen.width * 0.10`
   On a narrow display, fitting both a title and an artist into 140px-180px causes severe truncation. An explicit narrow screen threshold (e.g. when `useShortenedForm > 0` or width < threshold) should allow dropping the artist or defaulting to title-only compact form to preserve layout sanity.

## Files Involved
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml`: Single concatenated StyledText item causes right elision of the artist.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`: Screen width threshold calculation and media loader width constraints.
- `scripts/phase48-right-zone-assert.sh`: Needs assertion updates for separate title/artist AST checks and elision behavior.

## Suggested Fix Direction
1. Split the text into two dedicated elements or use a layout structure in `Media.qml`:
   - `titleText` with `Layout.fillWidth: true`, `elide: Text.ElideRight`, showing `cleanedTitle` in `colOnLayer1`.
   - `artistText` with `Layout.fillWidth: false`, showing `• ${escapedArtist}` in `colSubtext`.
   - When space contracts, `titleText` truncates with `...` while `artistText` remains fully visible.
2. In narrow mode (`useShortenedForm > 0` or threshold):
   - Conditionally hide `artistText` so narrow screens only display the title, preventing micro-fragmentation of the pill.
3. Update `scripts/phase48-right-zone-assert.sh` to verify:
   - Artist preserved while title elides.
   - Narrow screen threshold gating.
