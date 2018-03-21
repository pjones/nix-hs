{ pkgs ? (import <nixpkgs> {}).pkgs }:
pkgs.haskellPackages.callPackage ./@PROJECT@.nix { }
