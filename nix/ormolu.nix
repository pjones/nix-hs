{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { }
, compilerName }:

let
  package = import sources.ormolu {
    inherit pkgs;
    ormoluCompiler = compilerName;
  };
in pkgs.haskell.lib.justStaticExecutables package.ormolu
