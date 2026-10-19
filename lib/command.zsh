# The nitroshell command: menu, update, help, version, and the Ctrl+O key.

# nitroshell_update: update to the latest version
nitroshell_update() {
    # the version before the update (the loaded one stays old until the shell is restarted)
    local old_version=unknown new_version=unknown branch
    [[ -f "$NITROSHELL_DIR/VERSION" ]] && old_version=$(<"$NITROSHELL_DIR/VERSION")

    # the update resets the checkout to origin/main: do not destroy development work
    branch=$(git -C "$NITROSHELL_DIR" branch --show-current 2> /dev/null)
    if [[ "$branch" != main ]]; then
        echo "nitroshell: the repository is on branch '${branch:-?}', not main; refusing to update" >&2
        return 1
    fi

    if [[ -n "$(git -C "$NITROSHELL_DIR" status --porcelain 2> /dev/null)" ]]; then
        echo "nitroshell: the repository has local changes; commit or stash them first" >&2
        return 1
    fi

    if ! git -C "$NITROSHELL_DIR" fetch origin &> /dev/null || ! git -C "$NITROSHELL_DIR" reset --hard origin/main &> /dev/null; then
        echo "nitroshell: update failed" >&2
        return 1
    fi

    # the installer relinks the theme and keeps .zshrc in order
    NITROSHELL_DEST_DIR=$NITROSHELL_DIR sh "$NITROSHELL_DIR/install.sh" || return

    [[ -f "$NITROSHELL_DIR/VERSION" ]] && new_version=$(<"$NITROSHELL_DIR/VERSION")

    if [[ "$new_version" = "$old_version" ]]; then
        echo "Already up to date (version $new_version)."
    else
        echo "Updated: $old_version -> $new_version"
    fi
}

# nitroshell_help: usage of the non-interactive form
nitroshell_help() {
    echo "nitroshell $NITROSHELL_VERSION"
    echo
    echo "Usage: nitroshell [command]"
    echo
    echo "Without a command an interactive menu is shown."
    echo
    echo "Commands:"
    echo "  config [section]    settings (sections: ${(j:, :)${NITROSHELL_CONFIG_SECTIONS%%|*}})"
    echo "  update              update nitroshell to the latest version"
    echo "  version             show the current version"
    echo "  help                show this help"
}

# nitroshell_menu: main interactive menu
nitroshell_menu() {
    local start=1

    while true; do
        NITROSHELL_SELECT_START=$start
        nitroshell_select "nitroshell $NITROSHELL_VERSION" "↑/↓ move  Enter select  q quit" "Settings" "Update"
        start=$REPLY

        [[ "$NITROSHELL_KEY" = enter ]] || break

        case "$REPLY" in
            1) nitroshell_config ;;
            2) nitroshell_update; break ;;
        esac
    done
}

# nitroshell [command]: no command opens the interactive menu
nitroshell() {
    case "$1" in
        "")
            if [[ -t 0 ]]; then
                nitroshell_menu
            else
                nitroshell_help
            fi
            ;;
        config)
            if [[ ! -t 0 ]]; then
                echo "nitroshell: config is interactive, run it in a terminal" >&2
                return 1
            fi
            nitroshell_config "${@:2}"
            ;;
        update)
            nitroshell_update
            ;;
        version|-v|--version)
            echo "nitroshell $NITROSHELL_VERSION"
            ;;
        help|-h|--help)
            nitroshell_help
            ;;
        *)
            echo "nitroshell: unknown command '$1'" >&2
            return 1
            ;;
    esac
}

# Ctrl+O: open the nitroshell menu right below the prompt
nitroshell_widget() {
    print                  # step below the prompt line; the menu draws there and erases itself
    nitroshell_menu
    print -n '\e[1A'       # back to the line of the prompt
    configure_prompt
    zle reset-prompt
}

zle -N nitroshell_widget
bindkey ^O nitroshell_widget
