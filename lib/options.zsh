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

# space-separated commands that refuse to start while no proxy is set, e.g. "claude codex"
: ${REQUIRE_PROXY_FOR:=}

# save_option NAME VALUE: persist an option to the config file
save_option() {
    local name=$1 value=$2 line found=no
    local -a lines out

    # values with spaces have to be quoted, otherwise sourcing the file would run them
    [[ "$value" == *" "* ]] && value="\"$value\""

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
           PROMPT_MODE NEWLINE_BEFORE_PROMPT SHOW_GIT SHOW_PROXY SHOW_VENV REQUIRE_PROXY_FOR; do
    if [[ ! -f "$NITROSHELL_CONFIG_FILE" ]] || ! grep -q "^$opt=" "$NITROSHELL_CONFIG_FILE"; then
        save_option $opt ${(P)opt}
    fi
done
unset opt

# drop the obsolete option from the config file
if grep -q '^PROMPT_EXTRA_MODE=' "$NITROSHELL_CONFIG_FILE"; then
    print -rl -- "${(@f)$(grep -v '^PROMPT_EXTRA_MODE=' "$NITROSHELL_CONFIG_FILE")}" > "$NITROSHELL_CONFIG_FILE"
fi
unset PROMPT_EXTRA_MODE

### END OF OPTIONS
##################################################
