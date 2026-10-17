{
  description = "NixOS configuration with GNU Stow dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix packaging of AeroThemePlasma (Windows 7 look for Plasma), pinned in flake.lock.
    aerothemeplasma-nix = {
      url = "github:nyakase/aerothemeplasma-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma 6 widget for controlling Tailscale; built in home/brian/tailscale-widget.nix.
    tailscale-widget = {
      url = "github:DeadIndian/tailscale-widget";
      flake = false;
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
            nixos-hardware.nixosModules.microsoft-surface-pro-intel
            inputs.nix-index-database.nixosModules.default
            inputs.aerothemeplasma-nix.nixosModules.aerothemeplasma-nix
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
