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

, addDataFiles ? null
# ^ If not null, it should be a function that takes a path to the data
# directory and returns shell code to install extra files.
#
# Note: The argument given to this function contains shell variables
# so it can only be used in a shell snippet.
#
# Example:
#
#    addDataFiles = path: ''
#      mkdir -p "${path}/www"
#      for file in ${ui}/*.js; do
#        install -m 0444 "$file" "${path}/www"
#      done
#    '';

, compiler ? "default"
# ^ A nixpkgs version string for GHC, or "default".
}:

let

  # The final package set after modifying Haskell packages:
  pkgs_ = pkgs // {
    haskellPackages = haskell;
  };

  # Some library functions:
  lib = import ./nix/lib.nix { pkgs = pkgs_; };

  # Modified version of the nixpkgs Haskell lib:
  hlib = pkgs.haskell.lib // {
    inherit (lib) unBreak fetchGit;
  };

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
  drvSansAdditions =
    lib.benchmark
      (lib.appendBuildInputs buildInputs
        (lib.overrideSrc (dirOf (toString cabal))
          (haskell.callPackage (toString cabalNix) { })));

  drv = drvSansAdditions.overrideAttrs (_orig: {
    passthru = _orig.passthru or {} // {
      # Expose static binaries if requested:
      bin = hlib.justStaticExecutables drvSansAdditions;

      # An environment that includes common development tools such as
      # `cabal-install' and `hlint'.
      interactive = drvSansAdditions.env.overrideAttrs (orig: {
        buildInputs = orig.buildInputs ++
          (with haskell; [
            cabal-install
            hlint
            hasktags
          ]);
      });
    };
  });

in lib.addDataFiles haskell addDataFiles drv
