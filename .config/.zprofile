export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# Auto-start Hyprland only on a bare tty1 login (not inside an existing session).
# gnome-keyring is started/unlocked by PAM + systemd --user (pkcs11,secrets).
# SSH agent (if wanted): systemctl --user enable --now gcr-ssh-agent.socket
#   then export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
if [[ -z $DISPLAY && -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]; then
    exec start-hyprland
fi


# Added by Antigravity CLI installer
export PATH="/home/pera/.local/bin:$PATH"
