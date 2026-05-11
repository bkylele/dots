{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  swapDevices = [{
    device = "/swapfile";
    size = 4*1024;
  }];

  networking.hostName = "wapol";

  networking.networkmanager.enable = true;

  services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
  };

  time.timeZone = "America/Los_Angeles";

  users.users.brian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "1234";
  };

  # needed to allow nixos-rebuild over ssh
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    git
    vim
    tmux
  ];

  services.openssh.enable = true;

  ### Homelab Services (VPN & NAS)
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.0.0.1/24" ];
    listenPort = 51820;

    # This allows the server to share its internet connection with the VPN clients
    # We use a subshell to find the default network interface (e.g. enp3s0 or wlan0)
    postSetup = ''
      I=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/gawk '{print $5}')
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $I -j MASQUERADE
    '' ;

    postShutdown = ''
      I=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/gawk '{print $5}')
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o $I -j MASQUERADE
    '' ;

    # This path should contain the private key. 
    privateKeyFile = "/var/lib/wireguard/private.key";

    peers = [
      { # Buggy (Main PC)
        publicKey = "RcYqpYo5jPqjAhgnHpOYBM1AHERBKtseXV6medct6yI=";
        allowedIPs = [ "10.0.0.3/32" ];
      }
      { # Brian Phone
        publicKey = "rDP2R5LHPCjPTwIsKu4g2E4pO0HfyMinOTGFrcGPQUk=";
        allowedIPs = [ "10.0.0.2/32" ];
      }
      { # Dad's PC
        publicKey = "dKwSaeCWZwNLQ7DH/8IIR8M7Wl/uFO5JwSpL5x2wLH8=";
        allowedIPs = [ "10.0.0.4/32" ];
      }
      { # Dad's Phone
        publicKey = "9FMu84P1pLjl20P65t5d4ZnKLV9bgVsR1RwQxAZIxY=";
        allowedIPs = [ "10.0.0.5/32" ];
      }
    ];
  };

  # Open WireGuard port in the firewall
  networking.firewall.allowedUDPPorts = [ 51820 ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "wapol-nas";
        "netbios name" = "wapol";
        security = "user";
        # Allow local networks, VPN (10.x.x.x), and Tailscale (100.x.x.x)
        "hosts allow" = "192.168.1. 192.168.0. 10. 100. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      public = {
        path = "/srv/nas/public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
    };
  };

  services.filebrowser = {
    enable = true;
    # Run as nobody/nogroup to match Samba permissions for the public share
    user = "nobody";
    group = "nogroup";
    settings = {
      port = 8080;
      address = "0.0.0.0";
      root = "/srv/nas";
    };
  };

  # Ensure shared directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /srv/nas 0775 nobody nogroup -"
    "d /srv/nas/public 0775 nobody nogroup -"
    "d /srv/nas/brian 0775 nobody nogroup -"
    "d /srv/nas/family 0775 nobody nogroup -"
    "L+ /srv/nas/brian/shared - - - - /srv/nas/public"
    "L+ /srv/nas/family/shared - - - - /srv/nas/public"
    "Z /var/lib/filebrowser 0700 nobody nogroup -"
  ];

  # Open ports for Filebrowser web UI
  networking.firewall.allowedTCPPorts = [ 8080 ];

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
  system.stateVersion = "26.05"; # Did you read the comment?

}
