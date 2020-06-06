{ sources ? import ../nix/sources.nix, pkgs ? import sources.nixpkgs { }
, compiler ? "default" }:

let
  compilers = import ./compilers.nix { inherit pkgs; };
  ghc = compilers.name compiler;

  ghcide = import ../nix/ghcide.nix { inherit sources pkgs ghc; };
  ormolu = import ../nix/ormolu.nix { inherit sources pkgs ghc; };

in pkgs.mkShell {
  name = "nix-hs-shell-${ghc}";
  buildInputs = [ ghcide ormolu ] ++ (with pkgs; [ stack ])
    ++ (with pkgs.haskellPackages; [ cabal-install hasktags hlint hoogle ]);
}
