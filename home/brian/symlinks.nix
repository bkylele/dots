{ lib, pkgs, ... }:
let
  activate = pkgs.writeShellApplication {
    name = "dots-stow";
    runtimeInputs = [ pkgs.coreutils pkgs.stow ];
    text = builtins.readFile ./stow.sh;
  };
in
{
  environment.systemPackages = [ pkgs.stow activate ];

  # Run as the checkout owner after NixOS creates the account. A separate process
  # contains failures instead of exiting the activation shell.
  system.activationScripts.brian-dotfiles = {
    deps = [ "users" ];
    text = ''
      ${pkgs.util-linux}/bin/runuser -u brian -- ${lib.getExe activate}
    '';
  };
}
