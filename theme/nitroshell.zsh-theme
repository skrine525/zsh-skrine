#!/bin/zsh

##################################################
### OPTIONS

# user options live in config.zsh (next to the repository root, ignored by git)
NITROSHELL_CONFIG_FILE=${NITROSHELL_CONFIG_FILE:-${0:A:h:h}/config.zsh}

[[ -f "$NITROSHELL_CONFIG_FILE" ]] && . "$NITROSHELL_CONFIG_FILE"

# migrate the old PROMPT_EXTRA_MODE option
[[ -z "$SHOW_GIT" && "$PROMPT_EXTRA_MODE" = git ]] && SHOW_GIT=yes

# defaults for everything config.zsh did not set
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

    print -rl -- "${out[@]}" > "$NITROSHELL_CONFIG_FILE"
}

# add options missing from the config file, so new keys appear after an update
for opt in USE_SYNTAX_HIGHLIGHTING AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN \
           USE_ZSH_AUTOSUGGESTIONS AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN \
           PROMPT_MODE SHOW_GIT SHOW_PROXY SHOW_VENV REQUIRE_PROXY_FOR; do
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

# wrap every command from REQUIRE_PROXY_FOR
for cmd in ${=REQUIRE_PROXY_FOR}; do
    [[ "$cmd" =~ ^[A-Za-z0-9_.-]+$ ]] && functions[$cmd]="run_with_proxy_check $cmd \"\$@\""
done
unset cmd

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_proxy_info

### END OF PROXY INDICATOR
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

if [ "$USE_SYNTAX_HIGHLIGHTING" = yes ]; then

    syntax_highlighting=no

    # enable syntax-highlighting if avalaible

    if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 
        syntax_highlighting=yes
    fi

    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        syntax_highlighting=yes
    fi

    if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        syntax_highlighting=yes

    fi

    if [ "$syntax_highlighting" = no ]; then
        if [ "$AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN" = yes ]; then
            if whence -cp git &> /dev/null; then
                mkdir ~/.zsh >/dev/null 2>&1
                git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting >/dev/null 2>&1
                if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
                    . ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 
                    syntax_highlighting=yes
                else
                    echo "git not found, plugin zsh_syntax_highlighting not installed"
                fi
            fi
        fi
    fi    


    if [ "$syntax_highlighting" = yes ]; then
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

    unset syntax_highlighting

fi

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
### PROMPT SETTINGS MENU

# toggle_option NAME: flip a yes/no option and persist it
toggle_option() {
    if [[ "${(P)1}" = yes ]]; then
        typeset -g $1=no
    else
        typeset -g $1=yes
    fi

    save_option $1 ${(P)1}
}

# interactive menu (Ctrl+O): choose what is shown in the prompt
prompt_settings() {
    local key mark_git mark_proxy mark_venv

    while true; do
        [[ "$SHOW_GIT" = yes ]] && mark_git=x || mark_git=' '
        [[ "$SHOW_PROXY" = yes ]] && mark_proxy=x || mark_proxy=' '
        [[ "$SHOW_VENV" = yes ]] && mark_venv=x || mark_venv=' '

        zle -M "Show in prompt:
  1) [$mark_git] git
  2) [$mark_proxy] proxy
  3) [$mark_venv] python venv
1-3 toggle, any other key closes"
        zle -R  # flush the message now, otherwise it shows only after the next key
        read -srk1 key

        case "$key" in
            1)
                toggle_option SHOW_GIT
                # oh-my-zsh computes git info asynchronously and registers the handler only if
                # git_prompt_info was in the prompt at startup; register it for a live toggle
                if (( $+functions[_omz_register_handler] )); then
                    _omz_register_handler _omz_git_prompt_info
                    # start the first request now; the prompt is redrawn when it finishes
                    (( $+functions[_omz_async_request] )) && _omz_async_request
                fi
                ;;
            2)
                toggle_option SHOW_PROXY
                update_proxy_info
                ;;
            3) toggle_option SHOW_VENV ;;
            *)
                # swallow the rest of an escape sequence (arrow keys etc.)
                [[ "$key" = $'\e' ]] && while read -srk1 -t 0.05 key; do :; done
                break
                ;;
        esac

        configure_prompt
        zle reset-prompt
    done

    zle -M ""
    zle -R
}

zle -N prompt_settings
bindkey ^O prompt_settings

### END OF PROMPT SETTINGS MENU
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

if [ "$USE_ZSH_AUTOSUGGESTIONS" = yes ]; then

    zsh_autosuggestions=no

    # enable auto-suggestions based on completion and  history
    if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
        # change suggestion color
        ZSH_AUTOSUGGEST_STRATEGY=(completion history)
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
        zsh_autosuggestions=yes
    fi

    if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        # change suggestion color
        ZSH_AUTOSUGGEST_STRATEGY=(completion history)
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
        zsh_autosuggestions=yes
    fi

    if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        . /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 
        # change suggestion color
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
        ZSH_AUTOSUGGEST_STRATEGY=(completion history)
        zsh_autosuggestions=yes
    fi

    if [ "$zsh_autosuggestions" = no ]; then
        if [ "$AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN" = yes ]; then
            if whence -cp git &> /dev/null; then
                mkdir ~/.zsh >/dev/null 2>&1
                git clone --quiet https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions >/dev/null 2>&1
                if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
                    . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 
                    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
                    ZSH_AUTOSUGGEST_STRATEGY=(completion)
                    zsh_autosuggestions=yes
                fi
            else
                echo "git not found, plugin zsh_autosuggestions not installed"
            fi
        fi
    fi    
fi


# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi


##################################################
### ALIASES

# update-theme
alias update-theme="wget --no-cache -qO - https://raw.githubusercontent.com/skrine525/zsh-skrine/refs/heads/main/install.sh | sh"

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
