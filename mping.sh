#!/bin/bash

color() {
    case $1 in
        green)  echo -e "\033[0;32m$2\033[0m" ;;
        red)    echo -e "\033[0;31m$2\033[0m" ;;
        yellow) echo -e "\033[0;33m$2\033[0m" ;;
        *)      echo "$2" ;;
    esac
}

s=1
while getopts t: f; do
    [ "$f" = t ] && s=$OPTARG
done
shift $((OPTIND - 1))


[ $# -eq 0 ] && echo "Usage: $0 [-t seconds] host1 host2 ..." && exit
[[ ! "$s" =~ ^[0-9]+(\.[0-9]+)?$ ]] && echo "Invalid sleep time" && exit

while :; do
    out=""
    for h in "$@"; do
        if r=$(timeout "$s" ping -c1 "$h" 2>/dev/null); then
            t=$(awk -F"time=" '/time=/{print $2}' <<<"$r" |\
                awk '{print $1}')
            v=$(printf "%.0f" "$t" 2>/dev/null)
            # Choosing color
            if [ -n "$v" ]; then
                if [ "$v" -lt 100 ]; then
                    c=green
                elif [ "$v" -lt 500 ]; then
                    c=yellow
                else
                    c=red
                fi
            else
                c=yellow # Handle rounding error
            fi
        # Compose
        out+=$(color "$c" "$h: $t ms")" | "
        else
            out+=$(color red "$h: unreachable")" | "
        fi
    done
    echo "${out% | }"
    sleep "$s"
done
