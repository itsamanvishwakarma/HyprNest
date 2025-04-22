# Exports
export EDITOR=nvim
export PATH="$PATH:$HOME/.local/bin"
export ZSHRC="$HOME/.zshrc"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Time-stamp for zsh_history
HIST_STAMPS="dd/mm/yyyy"

# Source plugins
for dir in $HOME/.local/share/zsh-plugins/*/; do
    for file in "$dir"*plugin.zsh; do
        if [ -f "$file" ]; then
            source "$file" || echo "Error sourcing $file"
        fi
    done
done

# vim mode configurations
bindkey -v
export KEYTIMEOUT=1
# `menuselect` keymap becomes available when module `zsh/complist` is loaded
# The `supercharge` plugin sourced above already loads this module
# If you do not wish to use that plugin, you can enable it manually by uncommenting the below line:
# zmodload zsh/complist
if bindkey -M menuselect &>/dev/null; then
  bindkey -M menuselect 'h' vi-backward-char
  bindkey -M menuselect 'j' vi-down-line-or-history
  bindkey -M menuselect 'k' vi-up-line-or-history
  bindkey -M menuselect 'l' vi-forward-char
  bindkey -M menuselect 'left' vi-backward-char
  bindkey -M menuselect 'down' vi-up-line-or-history
  bindkey -M menuselect 'up' vi-up-line-or-history
  bindkey -M menuselect 'right' vi-forward-char
fi


# Aliases
alias ls='lsd --group-directories-first'
alias l='lsd -l --group-directories-first'
alias ll='lsd -l --group-directories-first'
alias la='lsd -la --group-directories-first'
alias tree='lsd -l --group-directories-first --tree --depth=2'
alias wifi="nmcli dev wifi"
alias diff="kitty +kitten diff"
alias zrc="$EDITOR $ZSHRC"

eval $(thefuck --alias)
eval "$(starship init zsh)"

fastfetch --kitty-direct ~/.config/fastfetch/fetch-images/kudo-shinichi.png
