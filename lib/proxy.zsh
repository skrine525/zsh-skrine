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
    [[ "$SHOW_PROXY" = yes ]] || return 0

    get_proxy_url
    local proxy=$REPLY
    [[ -n "$proxy" ]] || return 0

    proxy=${proxy#*://}  # drop scheme
    proxy=${proxy##*@}   # drop credentials
    proxy=${proxy%%/*}   # drop path
    NITROSHELL_PROXY_INFO=" %F{yellow}[proxy ${proxy//\%/%%}]%f"
}

# run_with_proxy_check COMMAND [ARGS...]: run COMMAND only if a proxy is set
run_with_proxy_check() {
    get_proxy_url
    if [[ -z "$REPLY" ]]; then
        nitroshell_error "$1: proxy is not set in the shell, refusing to start"
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

# the six variables, and where the ones set outside nitroshell wait while the proxy is off
NITROSHELL_PROXY_VARS=(http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY)
typeset -gA NITROSHELL_STASHED_PROXY

# proxy_available: succeeds when there is something to switch: configured addresses,
# a proxy set in the environment, or one that this shell switched off earlier
proxy_available() {
    proxy_configured && return
    (( ${#NITROSHELL_STASHED_PROXY} )) && return
    get_proxy_url
    [[ -n "$REPLY" ]]
}

# proxy_state: put on or off into REPLY
proxy_state() {
    if proxy_configured; then
        REPLY=${${PROXY_ENABLED:/yes/on}:/no/off}
    else
        get_proxy_url
        REPLY=${${REPLY:+on}:-off}
    fi
}

# toggle_proxy: switch the proxy on or off in this shell. Configured addresses are exported and
# removed; a proxy that came from the environment (.zshrc, the parent shell) is put aside and restored.
toggle_proxy() {
    local var

    if proxy_configured; then
        [[ "$PROXY_ENABLED" = yes ]] && PROXY_ENABLED=no || PROXY_ENABLED=yes
        apply_proxy_state
        return
    fi

    get_proxy_url
    if [[ -n "$REPLY" ]]; then
        for var in $NITROSHELL_PROXY_VARS; do
            [[ -n "${(P)var}" ]] && NITROSHELL_STASHED_PROXY[$var]=${(P)var}
        done
        unset $NITROSHELL_PROXY_VARS
    elif (( ${#NITROSHELL_STASHED_PROXY} )); then
        for var in ${(k)NITROSHELL_STASHED_PROXY}; do
            export $var=${NITROSHELL_STASHED_PROXY[$var]}
        done
        NITROSHELL_STASHED_PROXY=()
    else
        return 1
    fi

    update_proxy_info
}

# the state is per shell: it is not in the config. A shell started from one with the proxy on
# (exec zsh) inherits the variables, so it counts as on when they hold a configured address
PROXY_ENABLED=no
if [[ -n "$https_proxy$http_proxy$all_proxy" ]]; then
    for url in "$PROXY_HTTP" "$PROXY_HTTPS" "$PROXY_ALL"; do
        [[ -n "$url" && ( "$url" = "$https_proxy" || "$url" = "$http_proxy" || "$url" = "$all_proxy" ) ]] && PROXY_ENABLED=yes
    done
    unset url
fi

proxy_widget() {
    if toggle_proxy; then
        zle reset-prompt
        proxy_state
        zle -M "nitroshell: proxy $REPLY"
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
