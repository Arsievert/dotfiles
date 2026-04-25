#!/bin/bash

# Author:  Austin Sievert (arsievert1@gmail.com)
# URL:     https://github.com/arsievert1/dotfiles

# License: MIT

# Idempotent install script for a new macOS machine.
# Safe to re-run — each step checks whether it's already done.

set -e

DOTFILES_DIR="$HOME/dotfiles"

# Install Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed."
fi

# Install Fish
if ! command -v fish &>/dev/null; then
    echo "Installing Fish..."
    brew install fish
else
    echo "Fish already installed."
fi

# Install Starship
if ! command -v starship &>/dev/null; then
    echo "Installing Starship..."
    brew install starship
else
    echo "Starship already installed."
fi

# Set Fish as default shell
FISH_PATH="$(command -v fish)"
if ! grep -qxF "$FISH_PATH" /etc/shells; then
    echo "Adding Fish to /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    echo "Setting Fish as default shell..."
    chsh -s "$FISH_PATH"
else
    echo "Fish is already the default shell."
fi

# Sync dotfiles
echo "Syncing dotfiles..."
"$DOTFILES_DIR/bootstrap.sh"

echo "Done."
