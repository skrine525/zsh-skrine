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
        print -u2 "$1: proxy is not set in the shell, refusing to start (REQUIRE_PROXY_FOR)"
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
