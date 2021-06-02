{
  # Package sources:
  sources ? import ../../nix/sources.nix
  # nixpkgs:
, pkgs ? import sources.nixpkgs { }
  # Which version of GHC to use:
, compiler ? "default"
}:
let nix-hs = import ../../default.nix { inherit pkgs; };

in
nix-hs {
  cabal = ./hello-world.cabal;
  inherit compiler;
}
