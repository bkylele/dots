{ pkgs, ... }:
{
  # Keep the shell tied to the graphical session while using Quickshell's
  # standard ~/.config/quickshell/shell.qml discovery.
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Apply changed user units during a NixOS/Home Manager switch.
  systemd.user.startServices = "sd-switch";
}
