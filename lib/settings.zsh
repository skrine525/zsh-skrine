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
    "address|Proxy addresses"
    "proxy|Commands that require a proxy"
)

# section "address": the proxies that Ctrl+P and the main menu switch on and off
nitroshell_config_address() {
    local kind var url name start=1 had=no
    local -a kinds=(http https all) items

    proxy_configured && had=yes

    while true; do
        items=()
        for kind in $kinds; do
            mask_proxy ${(P)${:-PROXY_${(U)kind}}}
            name=${(U)kind}_PROXY
            items+=("${(r:11:)name} $REPLY")
        done

        NITROSHELL_SELECT_START=$start
        nitroshell_select "Proxy addresses" "↑/↓ move  Enter edit  d clear  q back" "${items[@]}"
        start=$REPLY

        case "$NITROSHELL_KEY" in
            quit) break ;;
            delete) url= ;;
            enter)
                kind=$kinds[REPLY]
                mask_proxy ${(P)${:-PROXY_${(U)kind}}}
                nitroshell_read "${(U)kind}_PROXY [$REPLY] (e.g. http://host:3128, - clears, Enter keeps): " || break
                url=$REPLY
                [[ -n "$url" ]] || continue
                [[ "$url" = - ]] && url=
                ;;
        esac

        var=PROXY_${(U)kinds[start]}
        typeset -g $var=$url
        save_option $var "$url"

        # the first address switches the proxy on; the last one removed switches it off
        if ! proxy_configured; then
            PROXY_ENABLED=no
        elif [[ $had = no ]]; then
            PROXY_ENABLED=yes
        fi
        had=no; proxy_configured && had=yes
        save_option PROXY_ENABLED "$PROXY_ENABLED"
        apply_proxy_state
        # clearing the last address leaves nothing configured: remove what was exported
        proxy_configured || unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        update_proxy_info
    done
}

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
                nitroshell_read "Command to add (empty to cancel): " || break
                cmd=$REPLY
                [[ -n "$cmd" ]] || continue

                if [[ ! "$cmd" =~ ^[A-Za-z0-9_.-]+$ ]]; then
                    nitroshell_error "Only letters, digits, '_', '.' and '-' are allowed."
                    continue
                elif (( ${cmds[(Ie)$cmd]} )); then
                    nitroshell_error "$cmd is already in the list."
                    continue
                fi

                (( $+commands[$cmd] )) || nitroshell_warn "$cmd was not found in PATH."
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
    local -a titles items

    # a section was given: open it directly
    if [[ -n "$1" ]]; then
        for entry in $NITROSHELL_CONFIG_SECTIONS; do
            if [[ "${entry%%|*}" = "$1" ]]; then
                nitroshell_config_${1}
                return
            fi
        done

        nitroshell_error "nitroshell: unknown settings section '$1'"
        nitroshell_error "Sections: ${(j:, :)${NITROSHELL_CONFIG_SECTIONS%%|*}}"
        return 1
    fi

    titles=(${NITROSHELL_CONFIG_SECTIONS#*|})

    while true; do
        # the first item switches the prompt mode right here, the rest open sections
        items=("Prompt mode: ${PROMPT_MODE/twoline/two lines}" "${titles[@]}")
        items[1]=${items[1]/oneline/one line}

        NITROSHELL_SELECT_START=$start
        nitroshell_select "nitroshell settings" "↑/↓ move  Enter select  q back" "${items[@]}"
        start=$REPLY

        [[ "$NITROSHELL_KEY" = enter ]] || break

        if (( REPLY == 1 )); then
            toggle_prompt_mode
        else
            entry=${NITROSHELL_CONFIG_SECTIONS[REPLY-1]}
            nitroshell_config_${entry%%|*}
        fi
    done
}

### END OF INTERACTIVE SETTINGS
##################################################
