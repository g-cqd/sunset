printf "\033[44m\033[2J\033[H\033[41mred\033[K\r\n\033[42mgreen\033[2K\r\n\033[43m"; for i in 1 2 3; do printf "\033[24;1H\n"; done; printf "\033[0mend\033[1;1H\033[3Pdel\033[2@ins\033[45m\033[3X"
