# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
nixos-rebuild switch --flake github:bkylele/.dotfiles#buggy 
```

I'm working on making all of my software configurations available through this
repository's flake, so my configuration per app is available through:

```bash
nix run codeberg.org/bkle/dots#neovim # or any other app
```

## TODO

- [X] Wrap neovim
- [X] Wrap kitty
- [ ] Wrap niri
- [ ] Wrap bash
- [ ] Wrap quickshell


## Quirks/Workarounds

Unlike on Arch linux, previous quirks and workarounds are now embedded in the
configuration (hurray nix!).
