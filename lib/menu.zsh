# Interactive menus: arrow-key selector and option toggle.

# toggle_option NAME: flip a yes/no option and persist it
toggle_option() {
    if [[ "${(P)1}" = yes ]]; then
        typeset -g $1=no
    else
        typeset -g $1=yes
    fi

    save_option $1 ${(P)1}
}

# nitroshell_read PROMPT: read a line into REPLY from the terminal. Works inside
# a zle widget (Ctrl+O), where stdin is not the terminal and echo is off; the
# prompt line is erased afterwards. Returns 1 on EOF.
nitroshell_read() {
    local saved ret
    saved=$(stty -g < /dev/tty 2> /dev/null)
    stty sane < /dev/tty 2> /dev/null
    print -n '\e[?25h'
    print -rn -- "$1"
    read -r REPLY < /dev/tty
    ret=$?
    [[ -n "$saved" ]] && stty "$saved" < /dev/tty 2> /dev/null
    print -n '\e[1A\r\e[J'
    return $ret
}

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

    # colors match the prompt: cyan frame, blue accents, grey hint
    local c_frame=$'\e[38;5;73m' c_sel=$'\e[1;38;5;73m' c_hint=$'\e[38;5;244m' c_on=$'\e[38;5;71m' c_off=$'\e[38;5;244m' c_rst=$'\e[0m' c_b=$'\e[1m'
    local lines=$(( count + 2 )) text

    print -n '\e[?25l'
    {
        local drawn=0
        while true; do
            (( drawn )) && print -n "\e[${lines}A"
            print -n '\e[J'
            print -r -- "${c_frame}┌─ ${c_b}${title}${c_rst}"
            for i in {1..$count}; do
                text=${items[i]}
                # color the checkbox of toggle items
                case "$text" in
                    '[x] '*) text="${c_on}[x]${c_rst}${text#\[x\]}" ;;
                    '[ ] '*) text="${c_off}[ ]${c_rst}${text#\[ \]}" ;;
                esac
                if (( i == cur )); then
                    print -r -- "${c_frame}│${c_rst}  ${c_sel}❯${c_rst} ${c_b}${text}${c_rst}"
                else
                    print -r -- "${c_frame}│${c_rst}    ${text}"
                fi
            done
            print -r -- "${c_frame}└─${c_rst} ${c_hint}${hint}${c_rst}"
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
        print -n "\e[${lines}A\e[J\e[?25h"
    }

    REPLY=$cur
}
