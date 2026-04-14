# Neovim config

## Phase 1: Reliability and Portability Baseline

This config is designed to work across Arch Linux, Debian/Ubuntu, and Windows with a unified buffer-first lifecycle model.

### Buffer, Window, and Tab Model

- **Buffer-first**: `<C-q>` closes the current buffer with confirmation if modified
- **Windows are layout only**: `<leader>xs` closes only the current split
- **Tabs are explicit workspaces**: Not affected by normal buffer-close commands

### Autosave Policy

- Autosave runs only on `FocusLost` for normal file buffers
- Checks: `buftype == ""`, `modifiable`, `modified`, non-empty filename
- Special buffers (terminal, quickfix, prompt, nofile, help) are never auto-written

### External Open Behavior

- `<C-S-o>` opens the current buffer's file with the system default application
- Neo-tree `<c-o>` opens the selected node with the same helper
- Uses `vim.ui.open()` for cross-platform support (Linux, macOS, Windows)

### Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Arch Linux | Tested | Uses system default app via vim.ui.open |
| Debian/Ubuntu | Tested | Same as Arch |
| Windows | Tested | Uses explorer.exe via vim.ui.open |

### Smoke Checklist

1. **Load test**: `nvim --headless "+qa"`
2. **External open**: Press `<C-S-o>` - should open in system default app
3. **Neo-tree open**: In neo-tree, press `<c-o>` on a file - should open externally
4. **Buffer close**: Press `<C-q>` on modified buffer - should prompt for confirmation
5. **Split close**: Press `<leader>xs>` - should close only current split
6. **Autosave**: Edit a file, switch focus away - should auto-save (FocusLost)

## Resources

- typecraft yt: [youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn](https://www.youtube.com/watch?v=iXIwm4mCpuc&list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn)
- Andrew Courter: [youtube.com/watch?v=NG7P_fPeuA8](https://www.youtube.com/watch?v=NG7P_fPeuA8)
- Henry Misc: [youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx](https://youtu.be/KYDG3AHgYEs?si=6Jfkb2AHaWKDDYmx)
- MrJackob (Much more detailed): [youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG](https://www.youtube.com/watch?v=g1gyYttzxcI&list=PLy68GuC77sURrnMNi2XR1h58m674KOvLG)
