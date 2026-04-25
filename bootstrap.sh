#!/bin/bash

# Author:  Austin Sievert (arsievert1@gmail.com)
# URL:     https://github.com/arsievert1/dotfiles

# License: MIT

# Sync dotfiles with home directory. Clone emacs config if it's not already there.

cd $HOME/dotfiles

rsync --exclude ".git/" \
      --exclude "Brewfile" \
      --exclude "LICENSE" \
      --exclude "README.org" \
      --exclude "bootstrap.sh" \
      --exclude "install.sh" \
      --exclude ".config/fish/fish_variables" \
      -avh --no-perms . $HOME

if [ ! -d "$HOME/.emacs.d/" ]; then
    cd $HOME
    git clone https://github.com/Arsievert/.emacs.d.git
fi
