{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      neovim = prev.callPackage ./stuff/nvim/neovim.nix { };
      kitty = inputs.kitty.packages.${prev.stdenv.hostPlatform.system}.default;
      hyprlock = inputs.hyprlock.packages.${prev.stdenv.hostPlatform.system}.default;
      hypridle = inputs.hypridle.packages.${prev.stdenv.hostPlatform.system}.default;
    })

    # (final: prev: {
    #   niri = inputs.niri.packages.${prev.stdenv.hostPlatform.system}.default;
    # })

    # (final: prev: {
    #   bash =
    #     if inputs.bash.packages ? ${prev.stdenv.hostPlatform.system}.default then
    #       inputs.bash.packages.${prev.stdenv.hostPlatform.system}.default
    #     else
    #       prev.bash;
    #   # bash = inputs.bash.packages.${prev.stdenv.hostPlatform.system}.default;
    # })

  ];
}
