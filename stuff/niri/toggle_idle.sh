#! /usr/bin/env -S nix shell nixpkgs#bash nixpkgs#libnotify --command bash

if [ $(pidof swayidle) ]; then
    kill $(pidof swayidle)
    notify-send "Screen idle stopped" "Screen will be kept awake"
else
    swayidle &
    notify-send "Screen idle started"
fi
