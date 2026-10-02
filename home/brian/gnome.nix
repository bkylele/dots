{ pkgs, ... }:
{
  # Keep the cursor and display-related fixes made after the GNOME migration,
  # but otherwise use GNOME's stock appearance and shell layout.
  home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.gnome-shell = {
    enable = true;
    extensions = [ ];
  };

  # Reset persisted values from the Windows 7 experiment to GNOME defaults.
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "Adwaita";
    icon-theme = "Adwaita";
    cursor-theme = "catppuccin-mocha-dark-cursors";
    cursor-size = 24;
    enable-hot-corners = true;
  };

  dconf.settings."org/gnome/desktop/wm/preferences".button-layout =
    "appmenu:close";
}
