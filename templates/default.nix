{ pkgs ? (import <nixpkgs> {}).pkgs }:
pkgs.haskellPackages.callPackage ./@NIX_FILE@ { }
