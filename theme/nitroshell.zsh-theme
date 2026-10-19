#!/bin/zsh

##################################################
### OPTIONS

# repository root (the theme file may be a symlink into it)
NITROSHELL_DIR=${0:A:h:h}

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

setopt autocd              # change directory just by typing its name
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt
setopt share_history       # all sessions share the same history files

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# the theme shows the virtualenv name itself (next to the path); otherwise activate prepends "(venv) " and breaks the first line
VIRTUAL_ENV_DISABLE_PROMPT=1

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action

setopt hist_verify            # show command with history expansion to user before running it

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

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

##################################################
### NEWLINE BEFORE PROMPT

# print an empty line before every prompt except the first one of the session
newline_before_prompt() {
    [[ "$NEWLINE_BEFORE_PROMPT" = yes && -n "$NITROSHELL_PROMPT_SHOWN" ]] && print
    NITROSHELL_PROMPT_SHOWN=1
}

add-zsh-hook precmd newline_before_prompt

# after clearing the screen the next prompt is the first one on it again
clear() {
    command clear "$@"
    NITROSHELL_PROMPT_SHOWN=
}

reset() {
    command reset "$@"
    NITROSHELL_PROMPT_SHOWN=
}

### END OF NEWLINE BEFORE PROMPT
##################################################

##################################################
### CONFIGURE PROMPT

configure_prompt() {
    if [[ " ${plugins[@]} " =~ " git " ]]; then
        ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[067]%}["
        ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
    fi

    if [[ $UID == 0 || $EUID == 0 ]]; then
        FGPROMPT="$FG[196]"
        CYANPROMPT="$FG[027]"
    else
        CYANPROMPT="$FG[073]"
        FGPROMPT="$FG[027]"
    fi

    local venv_info='' git_info=''
    [[ "$SHOW_GIT" = yes ]] && git_info=' $(git_prompt_info)'

    case "$PROMPT_MODE" in
        twoline)
            [[ "$SHOW_VENV" = yes ]] && venv_info='${VIRTUAL_ENV:+ (${VIRTUAL_ENV:t})}'
            PROMPT=$'$CYANPROMPT┌───\(%B$FGPROMPT%n@%m%b$CYANPROMPT)-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b$CYANPROMPT]'"$venv_info"'${NITROSHELL_PROXY_INFO}'"$git_info"$'$CYANPROMPT\n└─%B%(#.%F{red}#.$FGPROMPT$)%b%F{reset} '
            RPROMPT=
            ;;
        oneline)
            [[ "$SHOW_VENV" = yes ]] && venv_info='${VIRTUAL_ENV:+(${VIRTUAL_ENV:t})}'
            PROMPT=$'%B$FGPROMPT%n@%m%b%F{reset}:%B$CYANPROMPT%~%b%F{reset}%(#.#.$) '
            RPROMPT="$venv_info"'${NITROSHELL_PROXY_INFO}'"$git_info"
            ;;
    esac
}

configure_prompt

### END OF CONFIGURE PROMPT
##################################################

##################################################
### PLUGINS

# find_plugin NAME DOWNLOAD: put the path of the plugin script into REPLY.
# The plugin is cloned into ~/.zsh if it is not found and DOWNLOAD is yes.
# It is sourced by the caller, because a plugin sourced from a function would
# get its variables local to that function.
find_plugin() {
    local name=$1 download=$2 dir

    for dir in ~/.zsh/$name /usr/share/$name /usr/share/zsh/plugins/$name; do
        if [[ -f $dir/$name.zsh ]]; then
            REPLY=$dir/$name.zsh
            return 0
        fi
    done

    [[ "$download" = yes ]] || return 1

    if ! whence -cp git &> /dev/null; then
        echo "git not found, plugin $name not installed"
        return 1
    fi

    mkdir -p ~/.zsh
    git clone --quiet https://github.com/zsh-users/$name.git ~/.zsh/$name &> /dev/null

    if [[ -f ~/.zsh/$name/$name.zsh ]]; then
        REPLY=~/.zsh/$name/$name.zsh
        return 0
    fi

    return 1
}

if [ "$USE_SYNTAX_HIGHLIGHTING" = yes ] && find_plugin zsh-syntax-highlighting "$AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN"; then
    . "$REPLY"

    CL_CYAN="073"
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
    ZSH_HIGHLIGHT_STYLES[default]=none
    ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white,underline
    ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=$CL_CYAN,underline
    ZSH_HIGHLIGHT_STYLES[global-alias]=fg=$CL_CYAN,bold
    ZSH_HIGHLIGHT_STYLES[precommand]=fg=$CL_CYAN,underline
    ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=$CL_CYAN,underline
    ZSH_HIGHLIGHT_STYLES[path]=fg=white,bold
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
    ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[command-substitution]=none
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[process-substitution]=none
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=$CL_CYAN
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=$CL_CYAN
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[assign]=none
    ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
    ZSH_HIGHLIGHT_STYLES[named-fd]=none
    ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
    ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
    ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=$CL_CYAN,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
fi

if [ "$USE_ZSH_AUTOSUGGESTIONS" = yes ] && find_plugin zsh-autosuggestions "$AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN"; then
    . "$REPLY"

    # suggestions based on completion and history
    ZSH_AUTOSUGGEST_STRATEGY=(completion history)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
fi

### END OF PLUGINS
##################################################

##################################################
### TOGGLE PROMPT MODE

toggle_prompt_mode() {
    if [ "$PROMPT_MODE" = oneline ]; then
        PROMPT_MODE=twoline
    else
        PROMPT_MODE=oneline
    fi

    save_option PROMPT_MODE $PROMPT_MODE
    configure_prompt
    zle reset-prompt
}

zle -N toggle_prompt_mode
bindkey ^P toggle_prompt_mode

### END OF TOGGLE PROMPT MODE
##################################################

##################################################
### NITROSHELL MENU KEY (Ctrl+O)

# toggle_option NAME: flip a yes/no option and persist it
toggle_option() {
    if [[ "${(P)1}" = yes ]]; then
        typeset -g $1=no
    else
        typeset -g $1=yes
    fi

    save_option $1 ${(P)1}
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

### END OF NITROSHELL MENU KEY
##################################################

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    alias pacman='pacman --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

##################################################
### NITROSHELL COMMAND

# nitroshell_select TITLE HINT ITEM...: menu driven with the arrow keys.
# REPLY gets the number of the highlighted item and NITROSHELL_KEY the key that
# ended the menu: enter, delete (d, Backspace, Delete) or quit (q, Esc).
# NITROSHELL_SELECT_START is the item highlighted first (default 1).
nitroshell_select() {
    local title=$1 hint=$2 key rest i
    shift 2
    local -a items=("$@")
    local count=${#items} cur=${NITROSHELL_SELECT_START:-1}
    NITROSHELL_SELECT_START=

    (( cur > count )) && cur=$count
    (( cur < 1 )) && cur=1

    print -n '\e[?25l'
    {
        local drawn=0
        while true; do
            (( drawn )) && print -n "\e[$(( count + 3 ))A"
            print -n '\e[J'
            print -r -- "$title"
            for i in {1..$count}; do
                if (( i == cur )); then
                    print -r -- $'  \e[7m > '"${items[i]}"$' \e[0m'
                else
                    print -r -- "    ${items[i]}"
                fi
            done
            print
            print -r -- "$hint"
            drawn=1

            read -sk1 key || { NITROSHELL_KEY=quit; break }
            case "$key" in
                $'\e')
                    if read -sk1 -t 0.1 rest; then
                        if [[ "$rest" = '[' || "$rest" = O ]]; then
                            read -sk1 -t 0.1 rest
                            case "$rest" in
                                A) (( cur = cur > 1 ? cur - 1 : count )) ;;
                                B) (( cur = cur < count ? cur + 1 : 1 )) ;;
                                3) read -sk1 -t 0.1 rest; NITROSHELL_KEY=delete; break ;;
                            esac
                        fi
                    else
                        NITROSHELL_KEY=quit
                        break
                    fi
                    ;;
                k) (( cur = cur > 1 ? cur - 1 : count )) ;;
                j) (( cur = cur < count ? cur + 1 : 1 )) ;;
                $'\n'|$'\r'|' ') NITROSHELL_KEY=enter; break ;;
                d|$'\x7f') NITROSHELL_KEY=delete; break ;;
                q) NITROSHELL_KEY=quit; break ;;
            esac
        done
    } always {
        # erase the menu and bring the cursor back
        print -n "\e[$(( count + 3 ))A\e[J\e[?25h"
    }

    REPLY=$cur
}

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
        nitroshell_select "nitroshell $NITROSHELL_VERSION" "↑/↓ move  Enter select  q quit" "Prompt display" "Settings" "Update"
        start=$REPLY

        [[ "$NITROSHELL_KEY" = enter ]] || break

        case "$REPLY" in
            1) nitroshell_config_prompt ;;
            2) nitroshell_config ;;
            3) nitroshell_update; break ;;
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

### END OF NITROSHELL COMMAND
##################################################

##################################################
### ALIASES

# force zsh to show the complete history
alias history="history 0"

# ls
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# docker compose
alias dc='docker compose'

### END OF ALIASES
##################################################
