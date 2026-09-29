{ ... }:
{
  # Apply changed user units during a NixOS/Home Manager switch.
  systemd.user.startServices = "sd-switch";
}
