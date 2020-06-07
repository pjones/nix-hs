{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { }
, compilerName }:

(import sources.ormolu {
  inherit pkgs;
  ormoluCompiler = compilerName;
}).ormolu
