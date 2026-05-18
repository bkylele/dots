{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      devShells = eachSystem (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cowsay
            ];
          };
        }
      );
    };
}
