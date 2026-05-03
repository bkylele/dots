{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      neovim-custom = prev.callPackage ./stuff/nvim/default.nix { };
      kitty-custom = prev.callPackage ./stuff/kitty/default.nix { };
      hyprlock-custom = prev.callPackage ./stuff/hyprlock/default.nix { };
      hypridle-custom = prev.callPackage ./stuff/hypridle/default.nix { };
      swayidle-custom = prev.callPackage ./stuff/swayidle/default.nix { };
      bash-custom = prev.callPackage ./stuff/bash/default.nix { };
    })
  ];
}
