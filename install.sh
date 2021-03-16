#!/usr/env bash

#Update
sudo apt update

#Install packages
sudo apt install \
        vim \
        tmux \
        tig \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting

#Install configs
ln -s "${HOME}"/dotfiles/config/vim "${HOME}"/.vimrc
ln -s "${HOME}"/dotfiles/config/zshrc "${HOME}"/.zshrc

#Install vim plugins
vim +PlugInstall +qall

exit 0
