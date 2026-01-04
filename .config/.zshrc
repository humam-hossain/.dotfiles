# ==========================================
#  ZSH Configuration
# ==========================================

# --- 1. Path Definitions ---
# The location where setup.sh installed plugins
ZSH_CUSTOM="$HOME/.zsh"

# --- 2. History Settings ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt APPEND_HISTORY          # Append to history file immediately
setopt SHARE_HISTORY           # Share history between different shell sessions
setopt HIST_IGNORE_DUPS        # Don't record an entry that was just recorded again
setopt HIST_IGNORE_SPACE       # Don't record commands starting with a space

# --- 3. Basic Options ---
setopt AUTO_CD                 # Change directory just by typing its name
setopt CORRECT                 # Auto-correct simple command typos

# --- 4. Starship Prompt ---
# Initialize the prompt
eval "$(starship init zsh)"

# --- 5. Plugins ---

# A. Autosuggestions
if [ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    # Suggestion color (grey)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi

# B. Completion System (Standard "Tab to complete")
# We removed zsh-autocomplete to stop the automatic menu popups
autoload -Uz compinit && compinit

# Basic completion styling (makes the Tab menu look nice)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Use file colors
zstyle ':completion:*' menu select # Allow selecting with arrow keys

# C. Syntax Highlighting (MUST BE SOURCED LAST)
if [ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- 7. Aliases ---
alias ls='ls --color=auto'
alias ll='ls -lh'              # List human readable sizes
alias la='ls -lah'             # List all including hidden
alias grep='grep --color=auto'

# fzf keybindings
eval "$(fzf --zsh)"

# --- EDITOR ---
export EDITOR="nvim"

alias waybar_history="~/.config/waybar/history.sh"

