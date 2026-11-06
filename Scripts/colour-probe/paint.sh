#!/bin/bash
# paints stripes of known sRGB colours using truecolor backgrounds, then waits
printf '\033[?25l\033[2J'
colors=("255;0;0" "0;255;0" "0;0;255" "255;128;64" "128;128;128" "205;0;0" "30;60;200" "255;255;255")
row=1
for c in "${colors[@]}"; do
  printf '\033[%d;1H\033[48;2;%sm\033[K' "$row" "$c"
  row=$((row+1))
done
printf '\033[0m'
sleep 100
