{
  inputs,
  pkgs,
  ...
}:
let
  # Keep the upstream bundle immutable and apply the NixOS integration tweak in
  # the store.  The local `linux_maplestory/` directory is not an input.
  maplestoryBundle = pkgs.runCommandLocal "linux-maplestory-nixos" { } ''
    cp -a ${inputs.linux-maplestory}/. "$out"
    substituteInPlace "$out/install.sh" \
      --replace-fail \
        '    --skip-runtime) APPLY_RUNTIME=0; shift ;;' \
        '    --skip-fkeys) APPLY_FKEYS=0; PERSIST_FKEYS=0; shift ;;
    --skip-runtime) APPLY_RUNTIME=0; shift ;;'
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-extra.nix
    ../../modules/nixos/surface-ov5693-front-camera.nix
    ../../home/brian
  ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      efiSupport = true;
      device = "nodev";
    };
  };

  # Sized to match RAM (16 GiB) so a full hibernation image always fits.
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # in mebibytes
    }
  ];

  # systemd-sleep records the swapfile's device and offset in the
  # HibernateLocation EFI variable, and the systemd initrd resumes from it.
  # This avoids hardcoding resume_offset, which changes whenever the swapfile
  # is recreated.
  boot.initrd.systemd.enable = true;

  networking.hostName = "buggy";

  services.openssh.enable = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  networking.firewall.allowedUDPPorts = [ 51820 ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Denver";

  environment.sessionVariables = rec {
    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [ "${XDG_BIN_HOME}" ];
    HISTFILE = "$HOME/.local/state/.bash_history";
    TERMINAL = "kitty";
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  programs.nix-ld.enable = true;
  programs.nh.enable = true;
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Brian Le";
        email = "brian.k.le@proton.me";
      };

      pull.rebase = true;
      init.defaultBranch = "main";

      log = {
        decorate = "short";
        abbrevCommit = true;
      };

      url = {
        "git@github.com:" = {
          insteadOf = [ "gh:" ];
        };
        "https://codeberg.org/" = {
          insteadOf = [ "cb:" ];
        };
      };
    };
  };
  programs.nix-index-database.comma.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.firefox.enable = true;

  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "kitty.desktop" ];
      KDE = [ "kitty.desktop" ];
    };
  };

  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.fuse.userAllowOther = true;

  # MapleStory itself and its prefix are managed by Steam.  Keep the patch
  # bundle as a pinned flake input rather than vendoring it in this repository.
  boot.kernelModules = [ "hid-apple" ];
  boot.extraModprobeConfig = "options hid_apple fnmode=2";
  environment.systemPackages = [
    pkgs.protonup-qt
    pkgs.protontricks
    (pkgs.writeShellApplication {
      name = "maplestory-patch";
      runtimeInputs = with pkgs; [ coreutils gnugrep procps python3 ];
      text = ''
        exec ${maplestoryBundle}/install.sh --skip-fkeys "$@"
      '';
    })
  ];
  nixpkgs.config.allowUnfree = true;
  programs.kdeconnect.enable = true;

  # GUI applications such as XIVLauncher use the freedesktop Secret Service.
  services.gnome.gnome-keyring.enable = true;

  services.udev.packages = [ pkgs.vial ]; # udev rule for Vial to access keyboard hidraw device

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "overload(control, esc)";
      };
    };
  };
  services.tailscale.enable = true;
  # Let brian manage the Tailscale connection without root.
  services.tailscale.extraSetFlags = [ "--operator=brian" ];

  # User Profiles
  users.users.brian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input" # MapleStory's Wine DirectInput reads /dev/input/event*.
    ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
