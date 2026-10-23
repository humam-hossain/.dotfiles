# INFO: Powerlevel10k Instant Prompt

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# INFO: Path Definitions

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Define Custom plugin path (Preserved from your config)
export ZSH_CUSTOM="$HOME/.zsh"


# INFO: Theme Selection

ZSH_THEME="powerlevel10k/powerlevel10k"


# INFO: Starship (DISABLED)

# Starship initialization commented out as requested:
# eval "$(starship init zsh)"


# INFO: User Configuration

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


# INFO: Plugins

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


# INFO: Powerlevel10k Config File

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$HOME/.cargo/bin:$PATH"


# other aliases
alias define="bash $HOME/define.sh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/pera/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=/home/pera/.opencode/bin:$PATH

# nvim 
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/pera/.local/bin:$PATH"


# INFO: agentrouter
# export ANTHROPIC_BASE_URL=https://agentrouter.org/
# export ANTHROPIC_AUTH_TOKEN=REDACTED
# export ANTHROPIC_API_KEY=REDACTED

# kimi-code
export PATH="/home/pera/.kimi-code/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# claude
alias claude="TMPDIR=$HOME/.cache/claude-tmp claude --dangerously-skip-permissions"

# INFO: Ephemeral jrnl + gocryptfs Setup (Zsh)
export TMPDIR="/tmp"
setopt HIST_IGNORE_SPACE

j() {
    local MOUNT_POINT="$HOME/Vault"
    local CIPHER_DIR="$HOME/.vault_cipher"
    local WAS_MOUNTED=0

    # 1. Check if Vault is already mounted
    if mountpoint -q "$MOUNT_POINT"; then
        WAS_MOUNTED=1
    else
        echo "🔓 Unlocking encrypted storage..."
        gocryptfs "$CIPHER_DIR" "$MOUNT_POINT" || return 1
    fi

    # 2. Trap signals to handle cleanup on function exit in Zsh
    if [[ $WAS_MOUNTED -eq 0 ]]; then
        trap 'fusermount -u "$HOME/Vault" 2>/dev/null && echo "🔒 Vault unmounted and locked."; trap - EXIT INT TERM' EXIT INT TERM
    fi

    # 3. Use 'command' to execute the binary and avoid alias loops
    command jrnl "$@"
}

# Alias 'jrnl' with a leading space to trigger function 'j' while skipping history
alias jrnl=" j"
