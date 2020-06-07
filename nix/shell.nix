{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { }
, compiler ? "default" }:

let
  compilers = import ./compilers.nix { inherit pkgs; };
  compilerName = compilers.name compiler;

  ghcide = import ./ghcide.nix { inherit sources pkgs compilerName; };
  ormolu = import ./ormolu.nix { inherit sources pkgs compilerName; };

in pkgs.mkShell {
  name = "nix-hs-shell-for-${compilerName}";
  buildInputs = [ ghcide ormolu ] ++ (with pkgs; [ stack ])
    ++ (with pkgs.haskell.packages.${compilerName}; [
      ghc
      cabal-install
      hasktags
      hlint
      hoogle
    ]);
}
