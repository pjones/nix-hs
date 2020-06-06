{

# Package sources:
sources ? import ../../nix/sources.nix,

# nixpkgs:
pkgs ? import sources.nixpkgs { },

# Build a fully static executable?
static ? false,

# Which version of GHC to use:
compiler ? "default" }:

let nix-hs = import ../../default.nix { inherit pkgs; };

in nix-hs {
  inherit compiler;
  cabal = { hello-world = ../hello-world/hello-world.cabal; };
  enableFullyStaticExecutables = static;
}
