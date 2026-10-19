# Interactive settings (nitroshell config).

##################################################
### INTERACTIVE SETTINGS (nitroshell config)

# Settings sections shown in the "nitroshell config" menu, as "id|title".
# To add a section:
#   1. write a function nitroshell_config_<id> that shows and edits its options
#      with nitroshell_select in a loop and returns when the user goes back
#      (see nitroshell_config_proxy);
#   2. persist changes with save_option and re-apply them right away;
#   3. register it here.
# The section can be opened directly with "nitroshell config <id>".
NITROSHELL_CONFIG_SECTIONS=(
    "prompt|Prompt display"
    "proxy|Commands that require a proxy"
)

# section "proxy": commands that refuse to start without a proxy
nitroshell_config_proxy() {
    local cmd start=1
    local -a cmds items

    while true; do
        cmds=(${=REQUIRE_PROXY_FOR})
        items=("${cmds[@]}" "+ Add command")

        NITROSHELL_SELECT_START=$start
        nitroshell_select "Commands that require a proxy (REQUIRE_PROXY_FOR)" "↑/↓ move  Enter select  d delete  q back" "${items[@]}"
        start=$REPLY

        case "$NITROSHELL_KEY" in
            quit)
                break
                ;;
            delete)
                (( REPLY <= ${#cmds} )) || continue
                cmds[REPLY]=()
                ;;
            enter)
                (( REPLY > ${#cmds} )) || continue
                read -r "cmd?Command to add (empty to cancel): " || break
                [[ -n "$cmd" ]] || continue

                if [[ ! "$cmd" =~ ^[A-Za-z0-9_.-]+$ ]]; then
                    echo "Only letters, digits, '_', '.' and '-' are allowed."
                    continue
                elif (( ${cmds[(Ie)$cmd]} )); then
                    echo "$cmd is already in the list."
                    continue
                fi

                (( $+commands[$cmd] )) || echo "Note: $cmd was not found in PATH."
                cmds+=($cmd)
                start=${#cmds}
                ;;
        esac

        REQUIRE_PROXY_FOR="${cmds[*]}"
        save_option REQUIRE_PROXY_FOR "$REQUIRE_PROXY_FOR"
        apply_proxy_requirements
    done
}

# nitroshell_config_prompt: choose what is shown in the prompt
nitroshell_config_prompt() {
    local i start=1
    local -a opts=(SHOW_GIT SHOW_PROXY SHOW_VENV) labels=(git proxy "python venv") items

    while true; do
        items=()
        for i in {1..${#opts}}; do
            if [[ "${(P)opts[i]}" = yes ]]; then
                items+=("[x] ${labels[i]}")
            else
                items+=("[ ] ${labels[i]}")
            fi
        done

        NITROSHELL_SELECT_START=$start
        nitroshell_select "Show in the prompt" "↑/↓ move  Enter/Space toggle  q back" "${items[@]}"
        start=$REPLY

        [[ "$NITROSHELL_KEY" = enter ]] || break

        toggle_option ${opts[REPLY]}

        case "${opts[REPLY]}" in
            SHOW_GIT)
                # oh-my-zsh computes git info asynchronously and registers the handler only if
                # git_prompt_info was in the prompt at startup; register it for a live toggle
                if (( $+functions[_omz_register_handler] )); then
                    _omz_register_handler _omz_git_prompt_info
                    # start the first request now; the prompt is redrawn when it finishes
                    (( $+functions[_omz_async_request] )) && _omz_async_request
                fi
                ;;
            SHOW_PROXY)
                update_proxy_info
                ;;
        esac
    done
}

# nitroshell_config [SECTION]: interactive settings
nitroshell_config() {
    local entry start=1
    local -a titles

    # a section was given: open it directly
    if [[ -n "$1" ]]; then
        for entry in $NITROSHELL_CONFIG_SECTIONS; do
            if [[ "${entry%%|*}" = "$1" ]]; then
                nitroshell_config_${1}
                return
            fi
        done

        echo "nitroshell: unknown settings section '$1'" >&2
        echo "Sections: ${(j:, :)${NITROSHELL_CONFIG_SECTIONS%%|*}}" >&2
        return 1
    fi

    titles=(${NITROSHELL_CONFIG_SECTIONS#*|})

    while true; do
        NITROSHELL_SELECT_START=$start
        nitroshell_select "nitroshell settings" "↑/↓ move  Enter open  q back" "${titles[@]}"
        start=$REPLY

        [[ "$NITROSHELL_KEY" = enter ]] || break
        entry=${NITROSHELL_CONFIG_SECTIONS[REPLY]}
        nitroshell_config_${entry%%|*}
    done
}

### END OF INTERACTIVE SETTINGS
##################################################
