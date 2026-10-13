{ ... }:
{
  # pin control modules aren't loaded correctly for surface.
  # this fixes physical buttons not working
  boot.initrd.availableKernelModules = [ "pinctrl_tigerlake" ];

  # Suspend when pressing the power
  services.logind.settings.Login.HandlePowerKey = "suspend";

  # Surface GPE/Lid driver to enable wakeup from suspend via the lid.
  boot.blacklistedKernelModules = [ "surface_gpe" ];

  hardware.sensor.iio.enable = true;

  # The packaged unit is normally started by the sensor udev rule. On this
  # Surface the IIO devices can exist before that rule is applied, leaving
  # Plasma's Qt sensor backend waiting forever for SensorProxy.
  systemd.services.iio-sensor-proxy = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Keep the pen responsive while resting a palm on the display. Touch resumes
  # when the pen leaves proximity (pen + simultaneous finger gestures are off).
  services.iptsd.config.Touchscreen = {
    DisableOnPalm = true;
    DisableOnStylus = true;
  };

  # The upstream IPTSD rule only tags "add" events. This Surface's hidraw device
  # has lost its systemd tag on a later event, stopping the bound IPTSD service.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", KERNELS=="0001:045E:0C37.*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="iptsd@dev-%k.service"

    # The Surface HID sensors advertise both poll and buffer backends. The
    # buffer backend stalls SensorProxy claims for several seconds, so use
    # the working raw-value polling path for orientation and light instead.
    SUBSYSTEM=="iio", KERNELS=="HID-SENSOR-200073.6.auto", ENV{IIO_SENSOR_PROXY_TYPE}="iio-poll-accel"
    SUBSYSTEM=="iio", KERNELS=="HID-SENSOR-200041.4.auto", ENV{IIO_SENSOR_PROXY_TYPE}="iio-poll-als"
  '';

  # Give Plasma's tablet settings the Surface device database without replacing
  # the libwacom dependency of every application on the system.
  nixpkgs.overlays = [
    (_final: prev: {
      kdePackages = prev.kdePackages.overrideScope (
        _kfinal: kprev: {
          plasma-desktop = kprev.plasma-desktop.override { libwacom = prev.libwacom-surface; };
        }
      );
    })
  ];

  services.thermald.enable = true;
  # Plasma uses this for its power-mode controls.
  services.power-profiles-daemon.enable = true;
}
