{ pkgs ? import <nixpkgs> { }
}:

let
  nix-hs = import ../default.nix { inherit pkgs; };

in nix-hs {
  cabal = ./test.cabal;
}
