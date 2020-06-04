{ sources ? import ../nix/sources.nix, pkgs ? import sources.nixpkgs { } }:

let nix-hs = import ../default.nix { inherit pkgs; };

in nix-hs { cabal = ./test.cabal; }
