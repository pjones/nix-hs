{ sources ? import ./sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }
, compilerName ? (import ./compilers.nix { inherit pkgs; }).name "default"
}:
let
  haskell = pkgs.haskell.packages.${compilerName};
  lib = pkgs.haskell.lib;
  cabal-fmt = haskell.callCabal2nix "cabal-fmt" sources.cabal-fmt {
    Cabal = haskell.Cabal_3_2_0_0;
  };
in
lib.justStaticExecutables cabal-fmt
