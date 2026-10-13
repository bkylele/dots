{ ... }:
{
  # AeroThemePlasma: Windows 7 shell, KWin effects, SDDM theme and assets.
  # Packages come from the aerothemeplasma-nix flake input; user settings that
  # ATP's first-run wizard would write are declared in plasma-settings.nix.
  programs.aeroshell = {
    enable = true;
    fonts.segoe.enable = true;
    polkit.enable = true;
    aerothemeplasma = {
      enable = true;
      sddm.enable = true;
    };
  };

  # Wayland-only ATP session (aeroshell instead of plasmashell). X11 components
  # stay disabled because the X server is not enabled. Plain Plasma remains
  # selectable in SDDM.
  services.displayManager.defaultSession = "aerothemeplasma";
}
