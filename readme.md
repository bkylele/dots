# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
git clone https://codeberg.org/bkle/dots ~/dots && \
    cd ~/dots && \
    sudo nixos-rebuild switch --flake .#buggy
```

The `buggy` desktop uses GNOME on Wayland with GDM. The desktop
profile is managed by NixOS and Home Manager as part of the rebuild.
Application binaries are the normal Nixpkgs packages. Home Manager creates
out-of-store links from their native locations (`~/.config`, plus `~/.bashrc`)
to the files under `stuff/`, so edits in `~/dots` take effect directly.

The previous niri configuration remains under `stuff/niri/` for reference,
but it is not installed, linked, or offered as a login session. Kitty remains
the preferred terminal. Dolphin, Kate, Spectacle, and KDE Connect remain
available as standalone applications without the Plasma desktop.

The Home Manager configuration is split by purpose:

- `home/brian/packages.nix` contains user applications and Neovim plugins.
- `home/brian/symlinks.nix` maps editable dotfiles to their native locations.
- `home/brian/services.nix` contains Home Manager user-service behavior.

Keep the checkout at `~/dots`; the editable links and existing shell helpers
intentionally use that location. On the first rebuild, Home Manager preserves
any conflicting unmanaged file with the suffix `.hm-backup`.

## Quirks/Workarounds

Sometimes during `nixos-rebuild`, lower-end machines might run out of RAM. Also
on surface devices, thermal throttling is bugged out by default. To mitigate
this, make sure to limit the maximum jobs and cores used for the build:

```nix
nixos-rebuild switch --flake DOTS_PATH --max-jobs 1 --cores 1
```
