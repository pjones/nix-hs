################################################################################
#
# This file is part of the package nix-hs. It is subject to the license
# terms in the LICENSE file found in the top-level directory of this
# distribution and at:
#
#   https://code.devalot.com/open/nix-hs
#
# No part of this package, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in
# the LICENSE file.
#
{ pkgs ? import <nixpkgs> { }
}:

with pkgs.lib;

{ cabal
# ^ Path to cabal file.

, flags ? []
# ^ Cabal `-f' flags to use.

, overrides ? (lib: self: super: {})
# ^ Override `haskellPackages'.

, buildInputs ? []
# ^ Extra nixpkgs packages that your Haskell package depend on.

, compiler ? "default"
# ^ A nixpkgs version string for GHC, or "default".
}:

let

  # Some library functions:
  lib = import ./nix/lib.nix { inherit pkgs; };

  # Modified version of the nixpkgs Haskell lib:
  hlib = pkgs.haskell.lib // { inherit (lib) unBreak; };

  # The base package set we are going to override:
  packageSet =
    if compiler == "default"
    then pkgs.haskellPackages
    else pkgs.haskell.packages."ghc${compiler}";

  # The Haskell package environment after performing overrides:
  haskell = packageSet.override (orig: {
    overrides = composeExtensions
                 (orig.overrides or (_: _: {}))
                 (overrides hlib);
  });

  # The output of cabal2nix;
  cabalNix = import ./nix/cabal2nix.nix { inherit pkgs cabal flags; };

  # The actual derivation for the package:
  drv = lib.benchmark
          (lib.appendBuildInputs buildInputs
            (lib.overrideSrc (dirOf (toString cabal))
              (haskell.callPackage (toString cabalNix) { })));

  # An environment that includes common development tools such as
  # `cabal-install' and `hlint'.
  env = drv.env.overrideAttrs (orig: {
    passthru = orig.passthru or {} // {
      # Expose this package's executables if requested:
      bin = hlib.justStaticExecutables drv;
    };

    buildInputs = orig.buildInputs ++
      (with haskell; [
        cabal-install
        hlint
        hasktags
      ]);
  });

in if inNixShell
   then env
   else drv
