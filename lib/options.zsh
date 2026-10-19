# Options: the config file, defaults, persisting changes.

##################################################
### OPTIONS

# current version, kept in the VERSION file in the repository root
NITROSHELL_VERSION=unknown
[[ -f "$NITROSHELL_DIR/VERSION" ]] && NITROSHELL_VERSION=$(<"$NITROSHELL_DIR/VERSION")

# user options live in config/config.zsh (in the repository root, ignored by git)
NITROSHELL_CONFIG_FILE=${NITROSHELL_CONFIG_FILE:-$NITROSHELL_DIR/config/config.zsh}

# the config used to live in the repository root
if [[ ! -f "$NITROSHELL_CONFIG_FILE" && -f "$NITROSHELL_DIR/config.zsh" ]]; then
    mkdir -p "${NITROSHELL_CONFIG_FILE:h}" && mv "$NITROSHELL_DIR/config.zsh" "$NITROSHELL_CONFIG_FILE"
fi

[[ -f "$NITROSHELL_CONFIG_FILE" ]] && . "$NITROSHELL_CONFIG_FILE"

# migrate the old PROMPT_EXTRA_MODE option
[[ -z "$SHOW_GIT" && "$PROMPT_EXTRA_MODE" = git ]] && SHOW_GIT=yes

# defaults for everything the config file did not set
: ${USE_SYNTAX_HIGHLIGHTING:=yes}
: ${AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN:=yes}

: ${USE_ZSH_AUTOSUGGESTIONS:=yes}
: ${AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN:=yes}

: ${PROMPT_MODE:=twoline}
: ${NEWLINE_BEFORE_PROMPT:=yes}

: ${SHOW_GIT:=no}
: ${SHOW_PROXY:=yes}
: ${SHOW_VENV:=yes}

# proxy addresses (e.g. http://user:pass@host:3128, socks5://host:2080) and whether they are
# switched on in the shell (Ctrl+P); they become http_proxy/HTTP_PROXY, https_proxy/HTTPS_PROXY
# and all_proxy/ALL_PROXY. Whether the proxy is on is not stored: it lives in the current shell only
: ${PROXY_HTTP:=}
: ${PROXY_HTTPS:=}
: ${PROXY_ALL:=}

# migrate the single PROXY_URL option
if [[ -n "$PROXY_URL" && -z "$PROXY_HTTP$PROXY_HTTPS$PROXY_ALL" ]]; then
    PROXY_HTTP=$PROXY_URL PROXY_HTTPS=$PROXY_URL PROXY_ALL=$PROXY_URL
fi

# space-separated commands that refuse to start while no proxy is set, e.g. "claude codex"
: ${REQUIRE_PROXY_FOR:=}

# nitroshell_error MESSAGE: print an error to stderr, red with a cross, so that it stands out
nitroshell_error() {
    print -ru2 -- $'\e[1;31m✗\e[0;31m' "$*"$'\e[0m'
}

# nitroshell_warn MESSAGE: the same for a non-fatal notice, in yellow
nitroshell_warn() {
    print -ru2 -- $'\e[1;33m!\e[0;33m' "$*"$'\e[0m'
}

# save_option NAME VALUE: persist an option to the config file
save_option() {
    local name=$1 value=$2 line found=no
    local -a lines out

    # values with spaces or shell characters (a proxy URL may hold & ? $) have to be quoted, otherwise sourcing the file would run them
    [[ -n "$value" && "$value" != *[^A-Za-z0-9_.,:/@%+=-]* ]] || value=${(qq)value}

    [[ -f "$NITROSHELL_CONFIG_FILE" ]] && lines=("${(@f)$(<$NITROSHELL_CONFIG_FILE)}")

    for line in "${lines[@]}"; do
        if [[ "$line" == "$name="* ]]; then
            out+=("$name=$value")
            found=yes
        else
            out+=("$line")
        fi
    done

    [[ $found = no ]] && out+=("$name=$value")

    mkdir -p "${NITROSHELL_CONFIG_FILE:h}"
    print -rl -- "${out[@]}" > "$NITROSHELL_CONFIG_FILE"
}

# add options missing from the config file, so new keys appear after an update
for opt in USE_SYNTAX_HIGHLIGHTING AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN \
           USE_ZSH_AUTOSUGGESTIONS AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN \
           PROMPT_MODE NEWLINE_BEFORE_PROMPT SHOW_GIT SHOW_PROXY SHOW_VENV REQUIRE_PROXY_FOR PROXY_HTTP PROXY_HTTPS PROXY_ALL; do
    if [[ ! -f "$NITROSHELL_CONFIG_FILE" ]] || ! grep -q "^$opt=" "$NITROSHELL_CONFIG_FILE"; then
        save_option $opt ${(P)opt}
    fi
done
unset opt

# drop the obsolete options from the config file
if grep -q -E '^(PROMPT_EXTRA_MODE|PROXY_URL|PROXY_ENABLED)=' "$NITROSHELL_CONFIG_FILE"; then
    print -rl -- "${(@f)$(grep -v -E '^(PROMPT_EXTRA_MODE|PROXY_URL|PROXY_ENABLED)=' "$NITROSHELL_CONFIG_FILE")}" > "$NITROSHELL_CONFIG_FILE"
fi
unset PROMPT_EXTRA_MODE PROXY_URL

### END OF OPTIONS
##################################################
