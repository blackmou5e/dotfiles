#!/usr/bin/zsh

# tmux
rm ${HOME}/.tmux.conf || true
ln -sf ${PWD}/tmux/tmux.conf ${HOME}/.tmux.conf

# i3
rm -r ${HOME}/.config/i3 || true
ln -sf ${PWD}/i3 ${HOME}/.config/i3

# i3status
rm -r ${HOME}/.config/i3status || true
ln -sf ${PWD}/i3status ${HOME}/.config/i3status

# neovim
rm -r ${HOME}/.config/nvim || true
ln -sf ${PWD}/nvim ${HOME}/.config/nvim
