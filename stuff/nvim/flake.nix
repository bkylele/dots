{
  description = "My Neovim Configuration";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nvimPlugins = with pkgs.vimPlugins; [
          vim-fugitive
          vim-dispatch
          undotree
          nvim-surround
          oil-nvim
          no-neck-pain-nvim
          luasnip
          vim-snippets
          lean-nvim
        ];

        packpath = pkgs.runCommandLocal "packpath" { } ''
          mkdir -p $out/pack/nvim-custom/{start,opt}

          ${
            pkgs.lib.concatMapStringsSep
            "\n"
            (plugin: "ln -vsfT ${plugin} $out/pack/nvim-custom/start/${pkgs.lib.getName plugin}")
            nvimPlugins
          }
        '';

        nvimConfigPath = pkgs.runCommandLocal "nvim-config" { } ''
          mkdir -p $out/
          cp -r ${./.}/* $out/
        '';
      in
      {
        packages.default = pkgs.symlinkJoin {
          name = "neovim";
          paths = [ pkgs.neovim ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/nvim \
                --add-flags "--cmd 'set packpath^=${packpath}'" \
                --add-flags "--cmd 'set runtimepath^=${nvimConfigPath}'" \
                --add-flags "-u ${nvimConfigPath}/init.lua"
          '';

          meta.mainProgram = "nvim";
        };
      }
    );
}
