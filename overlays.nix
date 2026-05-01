{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      neovim = prev.callPackage ./stuff/nvim/default.nix { };
      kitty = inputs.kitty.packages.${prev.stdenv.hostPlatform.system}.default;
      hyprlock = inputs.hyprlock.packages.${prev.stdenv.hostPlatform.system}.default;
      hypridle = inputs.hypridle.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}
