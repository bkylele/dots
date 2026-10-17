{ inputs, pkgs, ... }:
let
  # Plasma 6 widget with a C++ QML backend, pinned through the tailscale-widget
  # flake input. upstream's install.sh builds into ~/.local; here the same CMake
  # project installs into the store, so the plasmoid lands in share/plasma/plasmoids
  # and the QML module in lib/qt-6/qml, both on the system profile paths Plasma searches.
  tailscale-widget = pkgs.stdenv.mkDerivation {
    pname = "tailscale-widget";
    version = "1.0-${inputs.tailscale-widget.shortRev or "dirty"}";
    src = inputs.tailscale-widget;

    nativeBuildInputs = with pkgs.kdePackages; [
      extra-cmake-modules
      wrapQtAppsHook
      pkgs.cmake
    ];
    buildInputs = with pkgs.kdePackages; [
      qtbase
      qtdeclarative
      kcoreaddons
      ki18n
      kirigami
      libplasma
    ];

    # Upstream metadata lacks these keys, so the system tray never lists the
    # widget. They make it selectable under the tray's Entries settings.
    postPatch = ''
      ${pkgs.lib.getExe pkgs.jq} '. + {
        "X-Plasma-NotificationArea": "true",
        "X-Plasma-NotificationAreaCategory": "SystemServices"
      }' package/metadata.json > metadata.json.new
      mv metadata.json.new package/metadata.json
    '';

    dontWrapQtApps = true;

    meta = {
      description = "Plasma 6 widget to control Tailscale";
      homepage = "https://github.com/DeadIndian/tailscale-widget";
      license = pkgs.lib.licenses.gpl3Plus;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in
{
  # The widget runs the `tailscale` CLI from PATH; services.tailscale (host
  # config) provides it and sets --operator=brian so no root is needed.
  environment.systemPackages = [ tailscale-widget ];
}
