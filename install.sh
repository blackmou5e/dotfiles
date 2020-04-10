#!/usr/env bash

#Update
sudo pacman -Suy

#install software from default repos
sudo pacman -S \
    xorg \
    xorg-server \
    xorg-init \
    xf86-video-nouveau \
    bspwm \
    sxhkd \
    alacritty \
    neovim \
    tmux \
    htop \
    newsboat \
    git \
    ranger \
    feh \
    pulseaudio \
    pulsemixer \
    picom \
    shellcheck \
    python-pip \
    awesome-terminal-fonts \
    curl #just in case

#Install AUR helper
mkdir "${HOME}"/tmp && \
    cd "${HOME}"/tmp && \
    git clone https://aur.archlinux.org/yay.git . && \
    makepkg -si && \
    cd "${HOME}" && \
    rm -r "${HOME}"/tmp

#Install AUR software
yay -S polybar ttf-nerd-fonts-hack-complete-git

#Install configs
git clone https://github.com/blackmou5e/dotfiles.git
ln -s "${HOME}"/dotfiles/.Xresources "${HOME}"/.Xresources
ln -s "${HOME}"/dotfiles/config/* "${HOME}"/.config/

exit 0
