# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
git clone https://codeberg.org/bkle/dots ~/dots && \
    cd ~/dots && \
    sudo nixos-rebuild switch --flake .#buggy
```

The `buggy` desktop uses KDE Plasma 6 on Wayland with SDDM. The desktop
profile is managed by NixOS and Home Manager as part of the rebuild.
Application binaries are the normal Nixpkgs packages. Home Manager creates
out-of-store links from their native locations (`~/.config`, plus `~/.bashrc`)
to the files under `stuff/`, so edits in `~/dots` take effect directly.

The previous niri configuration remains under `stuff/niri/` for reference,
but it is not installed, linked, or offered as a login session.
Kitty remains the preferred terminal, and Plasma's default Konsole package is
excluded.

The Home Manager configuration is split by purpose:

- `home/brian/packages.nix` contains user applications and Neovim plugins.
- `home/brian/symlinks.nix` maps editable dotfiles to their native locations.
- `home/brian/services.nix` contains Home Manager user-service behavior.

### Keep Awake widget

The local **Keep Awake** Plasma widget can be added from the panel's *Add
Widgets* menu after a rebuild. Clicking it toggles an idle/sleep inhibitor;
its highlighted power icon means it is active. It is backed by the
`~/.local/bin/keep-awake` command, so assign that command (with `toggle`) in
*System Settings → Keyboard → Shortcuts → Add New → Command or Script* to use
the same toggle from a keybind. The state is reset on logout/reboot.

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
