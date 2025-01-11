#!/bin/bash

REPO_URL="https://github.com/skrine525/zsh-skrine"
DEST_DIR="$HOME/.zsh-skrine"

# Проверяем, существует ли папка
if [ -d "$DEST_DIR" ]; then
    echo "Updating..."
    cd "$DEST_DIR" || exit 1
    git fetch origin
    git rebase origin/dev
else
    echo "Clonning..."
    git clone "$REPO_URL" "$DEST_DIR"
    git checkout dev
fi

ln -sf "$HOME/.zsh-skrine/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
zsh
