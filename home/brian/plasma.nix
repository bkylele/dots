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
      settings.General.InputMethod = "qtvirtualkeyboard";
    };
  };

  # No Kontact/Akonadi suite or screen reader pulled in by desktop defaults.
  programs.kde-pim.enable = false;
  services.orca.enable = false;

  # Maliit is the session keyboard; Qt Virtual Keyboard serves the greeter/lockscreen.
  environment.systemPackages = [
    pkgs.maliit-keyboard
    pkgs.hunspellDicts.en_US
  ];

  # Maliit's upstream default is /usr/share/hunspell, which does not exist on NixOS.
  nixpkgs.overlays = [
    (_final: prev: {
      maliit-keyboard = prev.maliit-keyboard.overrideAttrs (old: {
        cmakeFlags = old.cmakeFlags ++ [
          "-DHUNSPELL_DICT_PATH=${prev.hunspellDicts.en_US}/share/hunspell"
        ];
      });
    })
  ];

  # Maliit uses GSettings, not a KDE rc file. Lock these so rebuilds also restore
  # the tablet layout and language if a previous user setting differs.
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings."org/maliit/keyboard/maliit" = {
        active-language = "en";
        enabled-languages = [ "en" ];
        device = "tablet";
        predictive-text = true;
        spell-checking = true;
        spell-checking-languages = [ "en_US" ];
        stay-hidden = false;
      };
    }
  ];

  # Optional packages in the pinned nixpkgs Plasma module. Keep the existing
  # Dolphin, Kate and Spectacle, plus ktexteditor/kconfig/qtbase integration.
  # qtsensors is retained when the Surface's IIO autorotation support needs it.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
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
    union
    qrca
    discover
  ];
}
