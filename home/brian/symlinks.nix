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
    "kitty/kitty.conf".source = link "stuff/kitty/kitty.conf";
    "monitors.xml".source = link "stuff/gnome/monitors.xml";
    "user-dirs.dirs".source = link "stuff/xdg-user-dirs/user-dirs.dirs";

    "nvim/init.lua".source = link "stuff/nvim/init.lua";
    "nvim/lua".source = link "stuff/nvim/lua";

    # ~/.config/kak is intentionally a direct directory link to stuff/kak,
    # so Kakoune can manage its plugins/ sibling directory. Do not manage a
    # child here: Home Manager follows that directory link and would overwrite
    # the source kakrc in this repository.
  };

}
