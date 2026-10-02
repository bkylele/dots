# Borgden Dots

I like to experiment a lot with workflows, many things are subject to change.

## Installation

Using NixOS, you can just do:
```bash
git clone https://codeberg.org/bkle/dots ~/dots && \
    cd ~/dots && \
    sudo nixos-rebuild switch --flake .#buggy
```

The `buggy` desktop uses Plasma 6 on Wayland with SDDM. NixOS installs the
applications and runs GNU Stow as `brian` during activation (including
`nixos-rebuild switch`). `wapol` remains a headless server. Home Manager is no
longer used; Glide still has its own transitive Home Manager flake input.

`home/brian/` now contains ordinary NixOS modules: `packages.nix`, `plasma.nix`,
and `symlinks.nix`. Neovim remains unwrapped; Nix installs its existing plugins
under the system profile's `share/nvim/site/pack/dots/start`.

## Dotfiles and GNU Stow

Keep this checkout at `~/dots`. The actual configuration files live in
`stow/apps/`, mirroring their destination paths. Stow creates links from your
home directory directly to those files and directories:

| Destination | Source under `stow/apps/` |
| --- | --- |
| `~/.bashrc` | `.bashrc` |
| `~/.config/kitty/kitty.conf` | `.config/kitty/kitty.conf` |
| `~/.config/nvim/init.lua` | `.config/nvim/init.lua` |
| `~/.config/nvim/lua` | `.config/nvim/lua` |
| `~/.config/kak` | `.config/kak` (including locally managed plugins) |
| `~/.config/user-dirs.dirs` | `.config/user-dirs.dirs` |

`stuff/` retains the original copies and retired desktop configurations; none
are used by the new setup. Edit the files in `stow/apps/` going forward.
Kakoune's existing plugins were copied too, but remain Git-ignored local state.

The activation helper `dots-stow` preserves conflicting files, directories,
and old Home Manager links in `~/.local/state/dots-stow/backup.*` before linking.
It also retires the old Home Manager Neovim plugin directory. It refuses to
follow symlinked parent directories. Backed-up store links still depend on the
old store paths, so retain your previous NixOS generation until satisfied.

After installation, these commands can also be run manually, without `sudo`:

```bash
# Preview changes without touching files.
stow --dir="$HOME/dots/stow" --target="$HOME" --simulate --restow apps

# Create or refresh links (also done by nixos-rebuild).
stow --dir="$HOME/dots/stow" --target="$HOME" --restow apps

# Remove only the managed links; keep the source configurations.
stow --dir="$HOME/dots/stow" --target="$HOME" --delete apps
```

Manual Stow reports conflicts instead of backing them up; `dots-stow` performs
the same backup-and-link operation as activation. The next activation restores
links removed manually. Editing existing files in `stow/apps/` takes effect without
a rebuild. To manage another path, add its configuration under `stow/apps/` and
add its destination to `targets` in `home/brian/stow.sh` for conflict backups.
Keep shared parent directories real directories. See the
[GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html).

## Minimal Plasma

Dolphin, Kate, Spectacle and KDE Connect remain installed, with Kitty as the
terminal. All other optional Plasma packages are excluded except integration
needed by those apps (`ktexteditor`, `kconfig`, `qtbase`) and Surface autorotation
(`qtsensors`). The exclusions in `home/brian/plasma.nix` are:

- Apps: Konsole, Ark, Elisa, Gwenview, Okular, KHelpCenter, Discover, Qrca.
- Extras: Aurorae, browser integration, extra wallpapers, X11 KWin, Qt tools
  CLI (`qdbus`), Baloo widgets, Dolphin plugins, FFmpeg thumbnails, KRdp,
  Plasma Keyboard, Qt Virtual Keyboard, Union theme.
- Disabled defaults: KDE PIM (Akonadi and its runtime), Orca, Qt 5 integration.

NixOS's required Plasma components remain, including System Settings, KWallet,
Baloo, KRunner and the desktop utilities. Hardware integration (network, audio,
Bluetooth, power and rotation) remains enabled. This uses the upstream module's
required/optional boundary; it does not replace that module with a custom desktop.
Exclusion removes optional profile entries, not libraries still needed as
dependencies (for example, SDDM still uses Qt Virtual Keyboard).
The existing GNOME Keyring stays for applications using Secret Service.

For the first migration, save your work and preferably rebuild from a TTY,
because replacing GDM can terminate the graphical session. Reboot afterward.
NixOS rollback restores system packages, but Stow uses the live checkout and
does not roll back your dotfile edits.

## Quirks/Workarounds

Sometimes during `nixos-rebuild`, lower-end machines might run out of RAM. Also
on surface devices, thermal throttling is bugged out by default. To mitigate
this, make sure to limit the maximum jobs and cores used for the build:

```nix
nixos-rebuild switch --flake DOTS_PATH --max-jobs 1 --cores 1
```
