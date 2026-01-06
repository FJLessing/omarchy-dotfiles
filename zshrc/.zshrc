source ~/.config/fjs-dotfiles/zshrc/aliases.zsh

# bun completions
[ -s "/home/fj/.bun/_bun" ] && source "/home/fj/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
