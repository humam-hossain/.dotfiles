# Project Security & Agent Boundaries

## Confidentiality: Rclone Configuration & Secrets
- **STRICT PROHIBITION**: NEVER read, view, print, cat, grep, search, parse, edit, or display `/home/pera/.config/rclone/rclone.conf` or any file matching `*rclone.conf*`.
- NEVER output or expose OAuth tokens, refresh tokens, access tokens, client IDs, or client secrets.
- For rclone operations or fixes, provide the exact commands for the user to run interactively in their own terminal. NEVER run commands that read or dump config files.
