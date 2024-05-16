#!/usr/bin/bash

# tmux
rm ${HOME}/.tmux.conf || true
ln -sf ${PWD}/tmux/tmux.conf ${HOME}/.tmux.conf

# i3
rm -r ${HOME}/.config/i3 || true
ln -sf ${PWD}/i3 ${HOME}/.config/i3

# i3status
rm -r ${HOME}/.config/i3status || true
ln -sf ${PWD}/i3status ${HOME}/.config/i3status

# vim
rm ${HOME}/.vimrc || true
rm -r ${HOME}/.vim || true
ln -sf ${PWD}/vim/vimrc ${HOME}/.vimrc
ln -sf ${PWD}/vim/vim ${HOME}/.vim

#zsh
rm ${HOME}/.zshrc || true
rm ${HOME}/.zshenv || true
ln -sf ${PWD}/zsh/zshrc ${HOME}/.zshrc
ln -sf ${PWD}/zsh/zshenv ${HOME}/.zshenv
