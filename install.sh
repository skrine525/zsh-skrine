#!/bin/sh

REPO_URL="${NITROSHELL_REPO_URL:-https://github.com/skrine525/nitroshell}"
DEST_DIR="${NITROSHELL_DEST_DIR:-$HOME/.zsh/nitroshell}"
THEME_NAME="nitroshell"

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
THEMES_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}/themes"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

##################################################
### CHECK DEPENDENCIES

missing=""

if ! command -v zsh > /dev/null 2>&1; then
    missing="$missing\n  - zsh: install it with your package manager (apt install zsh, pacman -S zsh, ...)"
fi

if ! command -v git > /dev/null 2>&1; then
    missing="$missing\n  - git: needed to install and update the theme and the plugins"
fi

if [ ! -d "$OMZ_DIR" ]; then
    missing="$missing\n  - Oh My Zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

if [ -n "$missing" ]; then
    printf "Missing required dependencies:$missing\n"
    echo "Install them and run this script again."
    exit 1
fi

### END OF CHECK DEPENDENCIES
##################################################

##################################################
### INSTALL OR UPDATE

if [ -d "$DEST_DIR" ]; then
    echo "Updating..."

    if ! cd "$DEST_DIR"; then
        echo "Failed to change directory to $DEST_DIR. Exiting..."
        exit 1
    fi

    # config/ is ignored by git, so the reset does not touch user settings
    if ! git fetch origin > /dev/null 2>&1 || ! git reset --hard origin/main > /dev/null 2>&1; then
        echo "Updating failed. Exiting..."
        exit 1
    fi
else
    echo "Installing..."

    if ! mkdir -p "$(dirname "$DEST_DIR")"; then
        echo "Failed to create $(dirname "$DEST_DIR"). Exiting..."
        exit 1
    fi

    if ! git clone "$REPO_URL" "$DEST_DIR" > /dev/null 2>&1; then
        echo "Installing failed. Exiting..."
        exit 1
    fi
fi

### END OF INSTALL OR UPDATE
##################################################

##################################################
### LINK THE THEME

mkdir -p "$THEMES_DIR"
ln -sf "$DEST_DIR/theme/$THEME_NAME.zsh-theme" "$THEMES_DIR/$THEME_NAME.zsh-theme"

# the theme used to be called skrine-theme: keep old installations working
if [ -L "$THEMES_DIR/skrine-theme.zsh-theme" ]; then
    ln -sf "$DEST_DIR/theme/$THEME_NAME.zsh-theme" "$THEMES_DIR/skrine-theme.zsh-theme"
fi

### END OF LINK THE THEME
##################################################

##################################################
### ENABLE THE THEME IN .zshrc

enable_theme() {
    if [ ! -f "$ZSHRC" ]; then
        echo "$ZSHRC not found. Add this line to it before Oh My Zsh is loaded:"
        echo "    ZSH_THEME=\"$THEME_NAME\""
        return
    fi

    if grep -q "^ZSH_THEME=\"$THEME_NAME\"" "$ZSHRC"; then
        echo "Theme is already enabled in $ZSHRC."
        return
    fi

    if [ ! -f "$ZSHRC.pre-$THEME_NAME" ]; then
        cp "$ZSHRC" "$ZSHRC.pre-$THEME_NAME"
        echo "Backup of .zshrc saved to $ZSHRC.pre-$THEME_NAME"
    fi

    tmp_file="$(mktemp)" || return

    if grep -q "^ZSH_THEME=" "$ZSHRC"; then
        sed "s|^ZSH_THEME=.*|ZSH_THEME=\"$THEME_NAME\"|" "$ZSHRC" > "$tmp_file"
    elif grep -q "^[[:space:]]*\(source\|\.\)[[:space:]].*oh-my-zsh\.sh" "$ZSHRC"; then
        # ZSH_THEME has to be set before Oh My Zsh is loaded
        awk -v line="ZSH_THEME=\"$THEME_NAME\"" '
            !done && /^[[:space:]]*(source|\.)[[:space:]].*oh-my-zsh\.sh/ { print line; done = 1 }
            { print }
        ' "$ZSHRC" > "$tmp_file"
    else
        rm -f "$tmp_file"
        echo "Could not find where Oh My Zsh is loaded in $ZSHRC. Add this line before it:"
        echo "    ZSH_THEME=\"$THEME_NAME\""
        return
    fi

    # cat keeps the permissions and the symlink of .zshrc
    cat "$tmp_file" > "$ZSHRC"
    rm -f "$tmp_file"
    echo "Theme enabled in $ZSHRC."
}

enable_theme

### END OF ENABLE THE THEME IN .zshrc
##################################################

echo "Success. Restart your zsh (exec zsh)."
