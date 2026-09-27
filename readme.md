# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
git clone https://codeberg.org/bkle/dots ~/dots && \
    cd ~/dots && \
    sudo nixos-rebuild switch --flake .#buggy
```

The desktop profile is managed by Home Manager as part of the NixOS rebuild.
Application binaries are the normal Nixpkgs packages. Home Manager creates
out-of-store links from their native locations (`~/.config`, plus `~/.bashrc`)
to the files under `stuff/`, so edits in `~/dots` take effect directly.

The Home Manager configuration is split by purpose:

- `home/brian/packages.nix` contains user applications and Neovim plugins.
- `home/brian/symlinks.nix` maps editable dotfiles to their native locations.
- `home/brian/services.nix` contains user services such as Quickshell.

Keep the checkout at `~/dots`; the editable links and existing shell helpers
intentionally use that location. On the first rebuild, Home Manager preserves
any conflicting unmanaged file with the suffix `.hm-backup`.

## TODO

- Quickshell
    - dashboard
        - media control
        - resource monitor
            - check out caelestia dots? https://github.com/caelestia-dots/shell
    - notifications
        - low battery notification
    - power
    - app runner
    - network/bluetoth
    - audio
    - keybinds

## Quirks/Workarounds

Sometimes during `nixos-rebuild`, lower-end machines might run out of RAM. Also
on surface devices, thermal throttling is bugged out by default. To mitigate
this, make sure to limit the maximum jobs and cores used for the build:

```nix
nixos-rebuild switch --flake DOTS_PATH --max-jobs 1 --cores 1
```
