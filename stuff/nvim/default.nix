{ pkgs ? import <nixpkgs> { } }:
pkgs.callPackage ./neovim.nix { }
