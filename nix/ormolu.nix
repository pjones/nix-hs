{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { }, ghc }:

(import sources.ormolu {
  inherit pkgs;
  ormoluCompiler = ghc;
}).ormolu
