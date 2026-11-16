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

    # MapleStory Proton patch bundle; kept outside this dotfiles repository.
    linux-maplestory = {
      url = "github:oldschoola/linux_maplestory";
      flake = false;
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
      packages.x86_64-linux.ov5693-surface =
        self.nixosConfigurations.buggy.config.system.build.ov5693-surface;

      checks.x86_64-linux =
        let
          host = self.nixosConfigurations.buggy;
          camera = self.packages.x86_64-linux.ov5693-surface;
        in
        {
          ov5693-surface = camera;
          ov5693-surface-source = camera.patchedSource;
          ov5693-surface-precedence =
            host.pkgs.runCommand "ov5693-surface-precedence"
              {
                nativeBuildInputs = [ host.pkgs.kmod ];
              }
              ''
                module=$(modinfo -b ${host.config.system.modulesTree} -k ${camera.modDirVersion} -F filename ov5693)
                test "$(readlink -f "$module")" = '${camera}/lib/modules/${camera.modDirVersion}/updates/ov5693.ko'
                touch "$out"
              '';
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
