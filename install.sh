#!/usr/env bash

#Update
sudo apt update

#Install packages
sudo apt install vim tmux tig

#Install configs
git clone https://github.com/blackmou5e/dotfiles.git
ln -s "${HOME}"/dotfiles/config/vim "${HOME}"/.vimrc

#Install vim plugins
vim +PlugInstall +qall

exit 0
