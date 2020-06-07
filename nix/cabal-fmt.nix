{ sources, pkgs, compilerName }:

let
  haskell = pkgs.haskell.packages.${compilerName};
  lib = pkgs.haskell.lib;
  cabal-fmt = haskell.callCabal2nix "cabal-fmt" sources.cabal-fmt {
    Cabal = haskell.Cabal_3_2_0_0;
  };
in cabal-fmt
