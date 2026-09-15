# Nothing OS bits for ~/.zshrc. Source this file, or paste it in.
# Assumes oh-my-zsh is already set up; the prompt itself comes from starship.

# oh-my-zsh: keep the plugins, drop the theme (starship draws the prompt)
ZSH_THEME=""

# Fetch on every new shell: dot-matrix wordmark via kitty graphics, half-block logo elsewhere
if [[ $TERM == xterm-kitty ]]; then
    fastfetch -c "$HOME/.config/fastfetch/config-nothing.jsonc"
else
    fastfetch -c "$HOME/.config/fastfetch/config-nothing.jsonc" \
        --logo-type file --logo "$HOME/.config/fastfetch/nothing-logo.txt" \
        --logo-color-1 white --logo-color-2 red
fi

# Prompt: ~/.config/starship.toml. Put this AFTER any PATH exports so ~/.local/bin/starship is found.
command -v starship >/dev/null && eval "$(starship init zsh)"
