{ ... }:
{
  imports = [
    ./packages.nix
    ./symlinks.nix
    ./services.nix
  ];

  home = {
    username = "brian";
    homeDirectory = "/home/brian";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
  xdg.enable = true;
}
