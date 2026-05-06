# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
nixos-rebuild switch --flake git+https://codeberg.org/bkle/dots#buggy 
# or equivalently
git clone https://codeberg.org/bkle/dots && \
    cd dots && \
    nixos-rebuild switch --flake .
```

## TODO

- create nix flake templates
- Wrap niri
- Wrap quickshell
- quickshell
    - dashboard
        - power(?)
    - app runner

## Quirks/Workarounds

Sometimes during `nixos-rebuild`, lower-end machines might run out of RAM. Also
on surface devices, thermal throttling is bugged out by default. To mitigate
this, make sure to limit the maximum jobs and cores used for the build:

```nix
nixos-rebuild switch --flake DOTS_PATH --max-jobs 1 --cores 1
```
