{
    symlinkJoin,
    makeWrapper,
    niri,
    xwayland-satellite,
    xdg-desktop-portal,
    xdg-desktop-portal-gnome,
    xdg-desktop-portal-gtk,
}:
let
# REMOVED
# [R.] aalib                                                           1.4rc5
# [R.] desktop-file-utils                                              0.28
# [R.] desktops                                                        <none>
# [R.] etc-xdg-xdg-desktop-portal-niri-portals.conf                    <none>
# [R.] flatpak                                                         1.16.6
# [R.] gdk-pixbuf-loaders.cache                                        <none>
# [R.] geoclue                                                         2.7.2
# [R-] gnome-keyring                                                   48.0
# [R.] gnome-settings-daemon                                           49.1-gsettings-schemas
# [R.] gst-plugins-good                                                1.26.11
# [R.] libshout                                                        2.4.6
# [R.] malcontent                                                      0.13.1-lib
# [R.] opencore-amr                                                    0.1.6
# [R.] ostree                                                          2026.1
# [R.] security-wrapper-gnome-keyring-daemon-x86_64-unknown-linux-musl <none>
# [R.] swaylock.pam                                                    <none>
# [R.] taglib                                                          2.2.1
# [R.] twolame                                                         2017-09-27
# [R.] umockdev                                                        0.19.3
# [R.] unit-gcr-ssh-agent.service                                      <none>
# [R.] unit-gcr-ssh-agent.socket                                       <none>
# [R.] unit-xdg-autostart-if-no-desktop-manager.target                 <none>
# [R.] xdg-dbus-proxy                                                  0.1.6
# [R-] xdg-desktop-portal                                              1.20.4
# [R-] xdg-desktop-portal-gnome                                        49.0
# [R-] xdg-desktop-portal-gtk                                          1.15.3
in
symlinkJoin {
  name = "niri-custom";
  paths = [ niri ];
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    xwayland-satellite
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
  ];
  postBuild = ''
    wrapProgram $out/bin/niri \
        --add-flags "--config  ${./config.kdl}"
  '';
}
