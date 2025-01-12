#!/bin/zsh

REPO_URL="https://github.com/skrine525/zsh-skrine"
DEST_DIR="$HOME/.zsh/zsh-skrine"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is not installed. Please install it first."
    exit 1
fi

if [ ! -d "$HOME/.zsh" ]; then
    echo "Creating .zsh directory..."
    mkdir -p "$HOME/.zsh"
fi

if [ -d "$DEST_DIR" ]; then
    echo "Installing..."

    cd "$DEST_DIR" || { echo "Directory $DEST_DIR not found, exiting..."; exit 1; }
    git fetch origin > /dev/null 2>&1
    git reset --hard origin/dev > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Installing failed. Exiting..."
        exit 1
    fi

    ln -sf "$DEST_DIR/theme/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
    echo "Success. Restart your zsh."
else
    echo "Cloning..."

    git clone "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Updating failed. Exiting..."
        exit 1
    fi

    ln -sf "$DEST_DIR/theme/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
    echo "Success."
fi
