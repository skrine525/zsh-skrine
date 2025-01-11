#!/bin/zsh

REPO_URL="https://github.com/skrine525/zsh-skrine"
DEST_DIR="$HOME/.zsh-skrine"

if [ -d "$DEST_DIR" ]; then
    echo "Updating..."

    cd "$DEST_DIR" || exit 1
    git fetch --all
    git pull origin dev --rebase > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Git rebase failed. Exiting..."
        exit 1
    fi
else
    echo "Clonning..."
    
    git clone "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Git clone failed. Exiting..."
        exit 1
    fi
fi

ln -sf "$DEST_DIR/skrine-theme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/skrine-theme.zsh-theme"
echo "Success. Restart your zsh."
