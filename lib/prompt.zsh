# The prompt: layout, blank line between prompts, prompt mode (Ctrl+P).

# the theme shows the virtualenv name itself (next to the path); otherwise activate prepends "(venv) " and breaks the first line
VIRTUAL_ENV_DISABLE_PROMPT=1

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

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
