# Each query's reply, as the program reads it from the terminal (raw mode, a short wait for the last byte), printed on its own row.
stty raw -echo min 0 time 5
row=0
q() {
    printf "$2" >&2
    reply="$(dd bs=1 count=200 2>/dev/null | od -An -c | tr -s ' ' | tr -d '\n')"
    row=$((row + 1))
    printf '\033[%d;1H\033[K%s:%s' "$row" "$1" "$reply"
    # The replies are also written to $ORACLE_OUT when the harness gives one: that is what is compared, whatever the terminal draws.
    [ -n "${ORACLE_OUT:-}" ] && printf '%s:%s\n' "$1" "$reply" >> "$ORACLE_OUT"
}
q dsr5 '\033[5n'
q cpr '\033[3;7H\033[6n'
q xcpr '\033[4;9H\033[?6n'
q size '\033[18t'
q ansi-irm '\033[4$p'
q ansi-lnm '\033[20$p'
q dec-appcursor '\033[?1$p'
q dec-reverse '\033[?5$p'
q dec-origin '\033[?6$p'
q dec-wrap '\033[?7$p'
q dec-blink '\033[?12$p'
q dec-cursor '\033[?25$p'
q dec-mouse1000 '\033[?1000$p'
q dec-mouse1002 '\033[?1002$p'
q dec-mouse1003 '\033[?1003$p'
q dec-focus '\033[?1004$p'
q dec-sgr-mouse '\033[?1006$p'
q dec-alt1049 '\033[?1049$p'
q dec-paste '\033[?2004$p'
q dec-sync '\033[?2026$p'
q dec-colm '\033[?3$p'
q dec-unknown '\033[?9999$p'
q kbd '\033[?u'
q kbd-push '\033[>1u\033[?u\033[<u'
q cursor-after-wrap '\033[1;80Hx\033[6n'
q set-then-query '\033[?7l\033[?7$p\033[?7h'
q mouse-set-query '\033[?1000h\033[?1000$p\033[?1000l'
[ -n "${ORACLE_OUT:-}" ] && echo END >> "$ORACLE_OUT"
