{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # pin control modules aren't loaded correctly for surface.
  # this fixes physical buttons not working
  boot.initrd.availableKernelModules = [ "pinctrl_tigerlake" ];

  # Suspend when pressing the power
  services.logind.settings.Login.HandlePowerKey = "suspend";

  # Surface GPE/Lid driver to enable wakeup from suspend via the lid.
  boot.blacklistedKernelModules = [ "surface_gpe" ];

  hardware.sensor.iio.enable = true;

  services.thermald.enable = true;
  # GNOME uses this for the power-mode controls in its system menu.
  services.power-profiles-daemon.enable = true;
}
