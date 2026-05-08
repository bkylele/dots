#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#fuzzel --command bash

options="Poweroff\nReboot\nSuspend"
choice=$(echo -e "$options" | fuzzel --dmenu)

case "$choice" in
    "Suspend")      systemctl suspend ;;
    "Reboot")       systemctl reboot ;;
    "Poweroff")     systemctl poweroff ;;
    *)              exit 0 ;;
esac
