{ lib, pkgs, ... }:
{
  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = false;
  };
  services.displayManager = {
    defaultSession = "plasma";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  # No Kontact/Akonadi suite or screen reader pulled in by desktop defaults.
  programs.kde-pim.enable = false;
  services.orca.enable = false;

  # Optional packages in the pinned nixpkgs Plasma module. Keep the existing
  # Dolphin, Kate and Spectacle, plus ktexteditor/kconfig/qtbase integration.
  # qtsensors is retained when the Surface's IIO autorotation support needs it.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    aurorae
    plasma-browser-integration
    plasma-workspace-wallpapers
    konsole
    kwin-x11
    (lib.getBin qttools)
    ark
    elisa
    gwenview
    okular
    khelpcenter
    baloo-widgets
    dolphin-plugins
    ffmpegthumbs
    krdp
    plasma-keyboard
    qtvirtualkeyboard
    union
    qrca
    discover
  ];
}
