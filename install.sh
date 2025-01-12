#!/bin/zsh

REPO_URL="https://github.com/skrine525/zsh-skrine"
DEST_DIR="$HOME/.zsh/zsh-skrine"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Oh My Zsh is not installed. Please install it first."
    exit 1
fi

if [ ! -d "$HOME/.zsh" ]; then
    echo "Creating .zsh directory..."
    mkdir -p "$HOME/.zsh"
fi

if [ -d "$DEST_DIR" ]; then
    echo "Updating..."

    cd "$DEST_DIR" || exit 1
    git fetch origin > /dev/null 2>&1
    git reset --hard origin/dev > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Git rebase failed. Exiting..."
        exit 1
    fi

    ln -sf "$DEST_DIR/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
    echo "Success. Restart your zsh."
else
    echo "Cloning..."

    git clone "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Git clone failed. Exiting..."
        exit 1
    fi

    ln -sf "$DEST_DIR/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
    echo "Success."
fi
