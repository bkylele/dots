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

`home/brian/` contains ordinary NixOS modules for packages, Plasma, and Stow.
Neovim remains unwrapped; Nix installs its existing plugins
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

The old `stuff/` directory has been removed. Edit files in `stow/apps/`.
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

## Reproducible Plasma settings

Edit `home/brian/plasma-settings.nix` for KDE preferences. Each top-level key is
a filename in `~/.config`; its attributes are KConfig sections and settings.
Nested section names use `][`, for example `"services][kitty.desktop"`.
`plasma-config.nix` generates these files in the Nix store, then restores writable
copies during `nixos-rebuild switch` and before each graphical login for `brian`.
This keeps KDE's runtime writes out of the repository. GUI changes to managed
files are temporary: put lasting changes in Nix before rebuilding.

The configuration includes Se7enAero appearance, nine desktops in three rows,
custom shortcuts, Surface touchpad behavior, two bottom panels, and Dolphin,
Kate, and Spectacle preferences. The panel definition shares one layout across
screens 0 and 1: launcher, pager, tasks, tray, clock, and show-desktop button.
The old keep-awake shortcut was omitted because its executable is missing.

`plasma-theme.tar.xz` is an offline snapshot of the existing Se7enAero global
theme, Plasma style, Aurorae decorations, Win11 icons, Win7OS color scheme, and
Windows 7 wallpapers from `~/.local/share`. Nix installs those assets and links
the corresponding user theme directories to the store so local copies cannot
override them. `plasma-colors.ini` preserves the current palette. Aurorae is
retained because this theme requires it; no theme downloads happen at activation.

The first overwritten copy of each configuration file is preserved in
`~/.local/state/dots-plasma/backup/`; replaced local theme assets are moved into
`theme.*` directories there. Log out and back in after rebuilding: already-running
KDE processes may retain old settings, and the login step reapplies the selected
generation before Plasma starts. Rollback restores that generation's desktop
settings on the next login. The helper can also be run manually as `dots-plasma-apply`.

Monitor detection/layout history (`kwinoutputconfig.json`), session restore data,
recent files, caches, and KDE Connect pairing credentials remain local. The
managed desktop preferences and theme are reproducible; those device-specific
and private runtime files are not copied into Nix.

## Plasma packages

Dolphin, Kate, Spectacle and KDE Connect remain installed, with Kitty as the
terminal. All other optional Plasma packages are excluded except integration
needed by those apps (`ktexteditor`, `kconfig`, `qtbase`), Surface autorotation
(`qtsensors`), login/lock-screen typing (`qtvirtualkeyboard`), and Se7enAero
decorations (`aurorae`). The exclusions in
`home/brian/plasma.nix` are:

- Apps: Konsole, Ark, Elisa, Gwenview, Okular, KHelpCenter, Discover, Qrca.
- Extras: browser integration, extra wallpapers, X11 KWin, Qt tools
  CLI (`qdbus`), Baloo widgets, Dolphin plugins, FFmpeg thumbnails, KRdp,
  Plasma Keyboard, Union theme.
- Disabled defaults: KDE PIM (Akonadi and its runtime), Orca, Qt 5 integration.

NixOS's required Plasma components remain, including System Settings, KWallet,
Baloo, KRunner and the desktop utilities. Hardware integration (network, audio,
Bluetooth, power and rotation) remains enabled. This uses the upstream module's
required/optional boundary; it does not replace that module with a custom desktop.
Exclusion removes optional profile entries, not libraries still needed as
dependencies (for example, SDDM still uses Qt Virtual Keyboard).
The existing GNOME Keyring stays for applications using Secret Service.

## Surface tablet support

The Surface Pro 8 uses the existing linux-surface kernel, IPTSD touch/pen daemon,
IIO sensor service and Plasma Wayland. Tablet mode switches automatically with
the Type Cover; rotation support and Xournal++ for pen notes were already installed.

- Maliit is the session keyboard, selected in `plasma-settings.nix`. It opens for
  touch or pen focus, rather than mouse clicks. Its tablet layout, English language,
  suggestions and spell checking are declared through dconf in `plasma.nix`.
  The package override points Hunspell at the Nix-provided English dictionary.
- SDDM uses Qt Virtual Keyboard for touch login. Qt Virtual Keyboard also remains
  available for Plasma's lock screen. Do not globally set `QT_IM_MODULE=maliit`:
  KWin starts the input method for the Wayland session.
- IPTSD suppresses touchscreen contacts while a pen is nearby or a palm is
  detected. This improves writing, but prevents simultaneous pen-and-finger
  gestures. Change `DisableOnStylus` in `hardware-extra.nix` if you prefer those.
- A Surface-specific udev rule retains the touchscreen's systemd tag across
  device events, keeping its device-bound IPTSD service available. Plasma's
  tablet settings use the packaged Surface-aware libwacom database.
- Panels are 48 pixels tall for easier touch targets. Maliit brings its own Qt 5
  dependencies; the optional desktop-wide Qt 5 theme integration stays disabled.

After rebuilding, reboot to apply device rules and start a fresh desktop session.
Detach/fold the Type Cover, check rotation, tap a text field to open Maliit, and
test pen pressure/palm rejection in Xournal++. On-screen input still depends on
application text-input support; some XWayland applications may not summon it.
Useful diagnostics are `systemctl status 'iptsd@*'`, `journalctl -b -u 'iptsd@*'`,
and `monitor-sensor` (available through `nix shell nixpkgs#iio-sensor-proxy`).

References: [Maliit](https://github.com/maliit/keyboard),
[IPTSD settings](https://github.com/linux-surface/iptsd/blob/master/etc/iptsd.conf),
[SDDM input method](https://github.com/sddm/sddm/blob/develop/data/man/sddm.conf.rst.in).

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
