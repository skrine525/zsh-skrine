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
