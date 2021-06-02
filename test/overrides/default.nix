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
  cabal = ./overrides.cabal;
  inherit compiler;

  # A function that overrides the Haskell package set, returning a new
  # package set:
  overrides = lib: self: super: {

    # Let's add the hello-world package to our package set.  We'll
    # give it access to the final nixpkgs so that any Haskell packages
    # we override in here are also overridden for it:
    hello-world = import ../hello-world {
      inherit (lib) pkgs;
    };

    # If a package is broken because of failing tests we can un-break
    # the package and turn off its tests:
    pipes-text = lib.dontCheck (lib.unBreak super.pipes-text);
  };
}
