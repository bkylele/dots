{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      bash-custom = prev.callPackage ./stuff/bash/default.nix { };
      neovim-custom = prev.callPackage ./stuff/nvim/default.nix { };
      kitty-custom = prev.callPackage ./stuff/kitty/default.nix { };
      hyprlock-custom = prev.callPackage ./stuff/hyprlock/default.nix { };
      swayidle-custom = prev.callPackage ./stuff/swayidle/default.nix { };
      hypr-kdeconnect-fix = prev.callPackage ./stuff/hypr-kdeconnect-fix/default.nix { };
      niri-custom = prev.callPackage ./stuff/niri/default.nix { };
      quickshell-custom = prev.callPackage ./stuff/quickshell/default.nix { };
    })
  ];
}
