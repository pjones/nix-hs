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
  inherit compiler;
  cabal = {
    hello-world = ../hello-world/hello-world.cabal;

    # We're loading the same cabal file twice but that's just to
    # demonstrate that you can refer to more than one cabal file using
    # the `cabal` attribute.
    world-hello = ../hello-world/hello-world.cabal;
  };
}
