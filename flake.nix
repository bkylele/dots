{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
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
    {
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
            inputs.home-manager.nixosModules.home-manager
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
