# Plugins: syntax highlighting and autosuggestions.

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
