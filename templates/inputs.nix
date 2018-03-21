{ pkgs ? (import <nixpkgs> {}).pkgs }:

let
  # List any extra packages you want available while your package is
  # building or while in a nix shell:
  extraPackages = with pkgs; [ ];

  # Helpful if you want to override any Haskell packages:
  haskell = pkgs.haskellPackages;
in

# Load the local nix file and use the overrides from above:
haskell.callPackage ./@PROJECT@.nix {
  mkDerivation = { buildTools ? []
                 , ...
                 }@args:
    haskell.mkDerivation (args // {
      buildTools = buildTools ++ extraPackages;
    });
}
