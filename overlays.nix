{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      hypr-kdeconnect-fix = prev.callPackage ./stuff/hypr-kdeconnect-fix/default.nix { };
    })
  ];
}
