{ pkgs ? (import <nixpkgs> {}).pkgs
, ghc  ? pkgs.ghc
, file
}:

let
  # Load the local package:
  package = import file { pkgs = pkgs; };

  # Pull build inputs from the local package: (not sure why, but there
  # are some nulls in the buildInputs that we need to remove).
  buildInputs = builtins.filter (p: p != null)
    package.buildInputs;

in pkgs.haskell.lib.buildStackProject {
  name = package.name;
  buildInputs = buildInputs;
  inherit ghc;
}
