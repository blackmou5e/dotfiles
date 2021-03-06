#!/usr/bin/env bash

#Update
sudo apt update

#Install packages
sudo apt install \
        vim \
        tmux \
        tig \
        zsh \
        nodejs \
        zsh-autosuggestions \
        zsh-syntax-highlighting

#Install configs
ln -s "${HOME}"/dotfiles/config/vim "${HOME}"/.vimrc
ln -s "${HOME}"/dotfiles/config/zshrc "${HOME}"/.zshrc
ln -s "${HOME}"/dotfiles/config/tmux.conf "${HOME}"/.tmux.conf

#Install vim plugins
vim +PlugInstall +qall

#Install NF
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip -o /tmp/FiraCode.zip
unzip /tmp/FiraCode -d /tmp/fonts
mkdir -p "${HOME}"/.local/share/fonts
mv /tmp/fonts/* "${HOME}"/.local/share/fonts

exit 0
