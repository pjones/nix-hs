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

{ cabal
# ^ Path to cabal file.

, flags ? []
# ^ Cabal `-f' flags to use.

, overrides ? (lib: self: super: {})
# ^ Override `haskellPackages'.

, buildInputs ? []
# ^ Extra nixpkgs packages that your Haskell package depend on.

, enableFullyStaticExecutables ? false
# ^ Whether or not to build completely static executables.
#
# Very experimental.  Often broken.  See:
# https://github.com/nh2/static-haskell-nix

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

  # The package set to start with.
  pkgs_ = if enableFullyStaticExecutables
            then pkgs.pkgsMusl
            else pkgs;

  # Some library functions:
  lib = import ./nix/lib.nix { pkgs = pkgs_ // {haskellPackages = haskell;}; };

  # Modified version of the nixpkgs Haskell lib:
  hlib = pkgs_.haskell.lib // {
    inherit (lib) unBreak fetchGit;
  };

  # The base package set we are going to override:
  packageSet =
    if compiler == "default"
    then pkgs_.haskellPackages
    else pkgs_.haskell.packages."ghc${compiler}";

  # The Haskell package environment after performing overrides:
  haskell = packageSet.override (orig: {
    overrides = pkgs_.lib.composeExtensions
                 (orig.overrides or (_: _: {}))
                 (overrides hlib);
  });

  # The output of cabal2nix;
  cabalNix = import ./nix/cabal2nix.nix {
    inherit cabal flags;
    pkgs = pkgs_;
  };

  # The actual derivation for the package:
  drvSansAdditions =
    lib.benchmark
      (lib.appendBuildInputs buildInputs
        (lib.overrideSrc (dirOf (toString cabal))
        (haskell.callPackage (toString cabalNix) {
          mkDerivation = args: haskell.mkDerivation (args //
          (if enableFullyStaticExecutables then lib.makeStatic else {}));
        })));

  drv = drvSansAdditions.overrideAttrs (_orig: {
    passthru = _orig.passthru or {} // {
      # Expose static binaries if requested:
      bin = hlib.justStaticExecutables drvSansAdditions;

      # An environment that includes common development tools such as
      # `cabal-install' and `hlint'.
      interactive = (haskell.shellFor {
        withHoogle = true;
        packages = p: [drvSansAdditions];
      }).overrideAttrs (orig: {
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
