# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
#
# Use VSCode instead of neovim as your default editor
# export EDITOR="code"
#
# Set a custom prompt with the directory revealed (alternatively use https://starship.rs)
export PROMPT_DIRTRIM=2
# PS1="\W \[\e]0;\w\a\]$PS1"
PS1="[\w] $PS1"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
. "/home/blackmou5e/.local/share/bob/env/env.sh"


alias ls="ls --color"
alias tn="tmux -u new -s"
alias ts="tmux -u ls"
alias tc="tmux -u a -t"
