#!/usr/bin/bash

rm -r ~/.config/nvim
ln -sf $(pwd)/nvim ~/.config/nvim

rm -r ~/.tmux.conf
ln -sf $(pwd)/tmux/.tmux.conf ~/.tmux.conf
rm -r ~/.local/scripts
ln -sf $(pwd)/bin/.local/scripts ~/.local/scripts
