# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
HISTCONTROL=ignoredups
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
# unset PROMPT_COMMAND commented out

# zoxide MUST be last
eval "$(zoxide init bash)"

alias denji='mapfile -t selected < <(fzf -m --preview="bat --color=always {}")
[ ${#selected[@]} -gt 0 ] && nvim "${selected[@]}"'
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

export PATH="$PATH:$HOME/development/flutter/bin"

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
alias gitadog='git log --all --decorate --oneline --graph'
alias sad='cd ~/.config/waybar && ./switch.sh && pkill waybar && nohup waybar >/dev/null 2>&1 & && cd ~'
alias bore='~/.local/bin/switch-wallpaper.sh'
eval "$(starship init bash)"
alias openpdf='xdg-open 2>/dev/null'
alias loss='cd Downloads && cd college && openpdf 3rd.pdf && cd ~'
alias pyq='cd Downloads && cd college && openpdf 3rdSEM.pdf && cd ~'
alias den='
mapfile -t selected < <(fzf -m)
[ ${#selected[@]} -gt 0 ] && exec mpv "${selected[@]}"
'
alias films='cd ~/Downloads/Films || return; den'
export PATH="$HOME/.local/bin:$PATH"
