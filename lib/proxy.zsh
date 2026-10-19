# Proxy indicator and the commands that require a proxy.

##################################################
### PROXY INDICATOR

# get_proxy_url: put the proxy address from the shell environment into REPLY (empty if none)
get_proxy_url() {
    REPLY=${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-${all_proxy:-$ALL_PROXY}}}}}
}

# show a marker (without credentials) when a proxy is set in the shell environment
update_proxy_info() {
    NITROSHELL_PROXY_INFO=
    [[ "$SHOW_PROXY" = yes ]] || return

    get_proxy_url
    local proxy=$REPLY
    [[ -n "$proxy" ]] || return

    proxy=${proxy#*://}  # drop scheme
    proxy=${proxy##*@}   # drop credentials
    proxy=${proxy%%/*}   # drop path
    NITROSHELL_PROXY_INFO=" %F{yellow}[proxy ${proxy//\%/%%}]%f"
}

# run_with_proxy_check COMMAND [ARGS...]: run COMMAND only if a proxy is set
run_with_proxy_check() {
    get_proxy_url
    if [[ -z "$REPLY" ]]; then
        nitroshell_error "$1: proxy is not set in the shell, refusing to start (REQUIRE_PROXY_FOR)"
        return 1
    fi

    command "$@"
}

# apply_proxy_requirements: (re)create the wrappers for the commands from REQUIRE_PROXY_FOR
typeset -ga NITROSHELL_WRAPPED
apply_proxy_requirements() {
    local cmd

    for cmd in $NITROSHELL_WRAPPED; do
        unfunction $cmd 2> /dev/null
    done
    NITROSHELL_WRAPPED=()

    for cmd in ${=REQUIRE_PROXY_FOR}; do
        if [[ "$cmd" =~ ^[A-Za-z0-9_.-]+$ ]]; then
            functions[$cmd]="run_with_proxy_check $cmd \"\$@\""
            NITROSHELL_WRAPPED+=($cmd)
        fi
    done
}

apply_proxy_requirements

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_proxy_info

### END OF PROXY INDICATOR
##################################################

##################################################
### PROXY SWITCH (Ctrl+P)

# proxy_configured: succeeds when at least one proxy address is set in the config
proxy_configured() {
    [[ -n "$PROXY_HTTP$PROXY_HTTPS$PROXY_ALL" ]]
}

# mask_proxy URL: put the address without login and password into REPLY ("not set" if empty)
mask_proxy() {
    REPLY=${1:-not set}
    REPLY=${REPLY/:\/\/*@/://***@}
}

# apply_proxy_state: export the configured addresses (both lower and upper case names) when the
# proxy is on and remove all six variables when it is off; without addresses the environment is left alone
apply_proxy_state() {
    local kind url

    proxy_configured || return

    for kind in http https all; do
        url=${(P)${:-PROXY_${(U)kind}}}
        if [[ "$PROXY_ENABLED" = yes && -n "$url" ]]; then
            export ${kind}_proxy=$url ${(U)kind}_PROXY=$url
        else
            unset ${kind}_proxy ${(U)kind}_PROXY
        fi
    done

    update_proxy_info
}

# toggle_proxy: switch the configured proxy on or off and persist the choice
toggle_proxy() {
    proxy_configured || return 1

    toggle_option PROXY_ENABLED
    apply_proxy_state
}

apply_proxy_state

proxy_widget() {
    if toggle_proxy; then
        zle reset-prompt
        zle -M "nitroshell: proxy ${${PROXY_ENABLED:/yes/on}:/no/off}"
    else
        # zle -M shows the message below the prompt and clears it on the next key, but does not
        # render colors: show it, then repaint that line in red
        local msg="✗ nitroshell: no proxy addresses set; press Ctrl+O and choose Proxy"
        zle -M "$msg"
        zle -R
        print -n $'\e7\e[1B\r\e[2K\e[1;31m'"$msg"$'\e[0m\e8' > /dev/tty
    fi
}

zle -N proxy_widget
bindkey ^P proxy_widget

### END OF PROXY SWITCH
##################################################
