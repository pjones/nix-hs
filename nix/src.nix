{ pkgs ? import <nixpkgs> { }
}:

with pkgs.lib;

let

  overrides = import ./overrides.nix { inherit pkgs; };


  self = import ./cabal2nix.nix { inherit pkgs; };

in
