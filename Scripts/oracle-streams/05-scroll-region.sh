printf "\033[2J\033[H"; for i in 1 2 3 4 5 6 7 8; do printf "line %s\r\n" $i; done; printf "\033[3;6r\033[6;1H\n\n\033[3;1H\033M\033M"; printf "\033[r\033[24;1Hbottom"
