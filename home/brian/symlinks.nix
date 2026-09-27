{ config, ... }:
let
  # These are deliberately out-of-store links: edit files in ~/dots and the
  # running applications see the change immediately. Keep this repository at
  # ~/dots, as also assumed by the shell aliases in stuff/bash/bashrc.
  repository = "${config.home.homeDirectory}/dots";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repository}/${path}";
in
{
  home.file.".bashrc".source = link "stuff/bash/bashrc";

  xdg.configFile = {
    "hypr/hyprlock.conf".source = link "stuff/hyprlock/hyprlock.conf";
    "kitty/kitty.conf".source = link "stuff/kitty/kitty.conf";
    "swayidle/config".source = link "stuff/swayidle/config";
    "user-dirs.dirs".source = link "stuff/xdg-user-dirs/user-dirs.dirs";

    "niri/config.kdl".source = link "stuff/niri/config.kdl";
    "niri/battery_notif.sh".source = link "stuff/niri/battery_notif.sh";
    "niri/power_menu.sh".source = link "stuff/niri/power_menu.sh";
    "niri/screen_record.sh".source = link "stuff/niri/screen_record.sh";
    "niri/toggle_idle.sh".source = link "stuff/niri/toggle_idle.sh";

    "nvim/init.lua".source = link "stuff/nvim/init.lua";
    "nvim/lua".source = link "stuff/nvim/lua";

    "quickshell/shell.qml".source = link "stuff/quickshell/shell.qml";
    "quickshell/dashboard".source = link "stuff/quickshell/dashboard";
    "quickshell/notifications".source = link "stuff/quickshell/notifications";
    "quickshell/panels".source = link "stuff/quickshell/panels";
    "quickshell/runner".source = link "stuff/quickshell/runner";
    "quickshell/services".source = link "stuff/quickshell/services";
    "quickshell/widgets".source = link "stuff/quickshell/widgets";

    # Kakoune's plugin manager owns the sibling plugins/ directory.
    "kak/kakrc".source = link "stuff/kak/kakrc";
  };
}
