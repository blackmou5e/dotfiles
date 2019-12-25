#!/usr/bin/env bash

# Installing python3, neovim, tmux
apt install python3 python3-dev python3-pip neovim tmux cmake build-essentials git
pip3 install pynvim pylint black

#Installing vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# moving configs
$VIM_HOME=$HOME/.config/nvim
mkdir -p $VIM_HOME
cp init.vim $VIM_HOME/init.vim
cp tmux.conf $HOME/.tmux.conf

#Install plugins to vim
nvim +PlugInstall +q +q

#Compile YCM
# need to be done
