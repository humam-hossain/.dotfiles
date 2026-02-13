# ==========================================
#  Powerlevel10k Instant Prompt
# ==========================================
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==========================================
#  Path Definitions
# ==========================================
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Define Custom plugin path (Preserved from your config)
export ZSH_CUSTOM="$HOME/.zsh"

# ==========================================
#  Theme Selection
# ==========================================
ZSH_THEME="powerlevel10k/powerlevel10k"

# ==========================================
#  Starship (DISABLED)
# ==========================================
# Starship initialization commented out as requested:
# eval "$(starship init zsh)"

# ==========================================
#  User Configuration
# ==========================================

# --- History Settings ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY          # Append to history file immediately
setopt SHARE_HISTORY           # Share history between different shell sessions
setopt HIST_IGNORE_DUPS        # Don't record an entry that was just recorded again
setopt HIST_IGNORE_SPACE       # Don't record commands starting with a space

# --- Basic Options ---
setopt AUTO_CD                 # Change directory just by typing its name
unsetopt CORRECT               # Disable auto-correct simple command typos

# --- Editor ---
export EDITOR="nvim"

# --- Aliases ---
alias ls='ls --color=auto'
alias ll='ls -lh'              # List human readable sizes
alias l='ls -lh'               # List human readable sizes
alias la='ls -lah'             # List all including hidden
alias grep='grep --color=auto'
alias waybar_history="~/.config/waybar/history.sh"

# --- FZF Keybindings ---
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh)"
fi

# ==========================================
#  Plugins
# ==========================================
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ==========================================
#  Powerlevel10k Config File
# ==========================================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# other aliases
alias define="bash $HOME/define.sh"
