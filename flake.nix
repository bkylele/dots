{
  description = "System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glide = {
      url = "github:glide-browser/glide.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        neovim = pkgs.callPackage ./stuff/nvim/default.nix { };
        bash = pkgs.callPackage ./stuff/bash/default.nix { };
        quickshell = pkgs.callPackage ./stuff/quickshell/default.nix { };
      };

      templates = {
        default = {
          path = ./templates/default;
          description = "useful flake template";
        };
      };

      nixosConfigurations = {
        buggy = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/buggy/configuration.nix
            ./overlays.nix
            nixos-hardware.nixosModules.microsoft-surface-pro-intel
            inputs.nix-index-database.nixosModules.default
          ];
        };

        wapol = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/wapol/configuration.nix
          ];
        };
      };
    };
}
