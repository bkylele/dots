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

  # pin control modules aren't loaded correctly for surface.
  # this fixes physical buttons not working
  boot.initrd.availableKernelModules = [ "pinctrl_tigerlake" ];

  # Suspend when pressing the power
  services.logind.settings.Login.HandlePowerKey = "suspend";

  # Surface GPE/Lid driver to enable wakeup from suspend via the lid.
  boot.blacklistedKernelModules = [ "surface_gpe" ];

  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4 * 1024; # in mebibytes
    }
  ];

  networking.hostName = "buggy";

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    address = [ "10.0.0.3/24" ];
    privateKeyFile = "/etc/wireguard/private.key";

    peers = [
      {
        # wapol (Server)
        publicKey = "YwDqFM0LRzBorhFpYOrdCCNN/vgpgN36K/4vo4ObjWY=";
        allowedIPs = [ "10.0.0.0/24" ];
        endpoint = "72.211.196.8:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Los_Angeles";

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
        "https://github.com/" = {
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
  # programs.niri.enable = true;
  programs.steam.enable = true;

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

  # User Profiles
  users.users.brian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # System Profile
  environment.systemPackages =
    let
      termPkgs = with pkgs; [
        htop
        zoxide
        fzf
        ripgrep
        fd
        bat
        btop
        xdg-user-dirs
        bash-custom
        neovim-custom
      ];
      guiPkgs = with pkgs; [
        brightnessctl
        wl-clipboard
        wf-recorder
        slurp
        nautilus
        mako
        quickshell
        mpv
        imv
        rofi
        (discord.override { withVencord = true; })
        catppuccin-cursors.mochaDark
        niri-custom
        hyprlock-custom
        swayidle-custom
        kitty-custom
      ];
    in
    termPkgs ++ guiPkgs;

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
