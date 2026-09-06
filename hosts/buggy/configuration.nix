{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-extra.nix
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

  swapDevices = [
    {
      device = "/swapfile";
      size = 4 * 1024; # in mebibytes
    }
  ];

  networking.hostName = "buggy";

  services.openssh.enable = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  networking.firewall = rec {
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedTCPPortRanges = allowedUDPPortRanges;
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Denver";

  environment.sessionVariables = rec {
    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [ "${XDG_BIN_HOME}" ];
    HISTFILE = "$HOME/.local/state/.bash_history";
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
        email = "contact@brianle.4wrd.cc";
      };

      pull.rebase = true;
      init.defaultBranch = "main";

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
  programs.direnv.enable = true;
  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.fuse.userAllowOther = true;
  nixpkgs.config.allowUnfree = true;
  programs.kdeconnect.enable = true;

  services.gvfs.enable = true; # required for certain nautilus functions
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # login handled by niri/session locker
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "brian";
      };
    };
  };
  services.gnome.gnome-keyring.enable = true;
  services.tailscale.enable = true;
  # Lets brian run `tailscale up/down` without root, so the dashboard VPN toggle works.
  services.tailscale.extraSetFlags = [ "--operator=brian" ];

  # User Profiles
  users.users.brian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # System Profile
  environment.systemPackages = with pkgs; [
    htop
    zoxide
    fzf
    ripgrep
    fd
    bat
    btop
    antigravity-ide
    claude-code
    xdg-user-dirs
    libnotify
    brightnessctl
    wluma
    wl-clipboard
    wf-recorder
    slurp
    nautilus
    kdePackages.dolphin
    quickshell
    mpv
    imv
    rofi
    vesktop
    slack
    xournalpp
    inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default
    catppuccin-cursors.mochaDark
    xwayland-satellite
    scrcpy
    android-tools
    iio-niri
    bash-custom
    neovim-custom
    hyprlock-custom
    swayidle-custom
    kitty-custom
  ];

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
