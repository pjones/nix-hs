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
# Functions for manipulating entire package sets.
{
  # The `lib` attribute from nixpkgs.
  lib

  # Haskell library functions from nixpkgs plus additions from nix-hs:
, haskell

  # The GHC functions from nix-hs:
, ghc
}:

rec {
  # Overrides Haskell packages in the given nixpkgs set, returning a
  # new nixpkgs set.
  #
  # The given function takes three arguments and returns a new Haskell
  # package set (see `overrideHaskellPackages` for more details):
  #
  # 1. The final nixpkgs set being generated.
  # 2. The final Haskell package set being generated.
  # 3. The current Haskell package set.
  overrideHaskellPackagesIn = f: pkgs:
    let
      overlay = self: super: {
        haskell = super.haskell // {
          packages = super.haskell.packages // {
            ${ghc.attrName} =
              overrideHaskellPackages
                (f self)
                super.haskell.packages.${ghc.attrName};
          };
        };
      };
    in
    pkgs.appendOverlays [ overlay ];

  # Override the given Haskell package set.
  #
  # The given function should take two arguments (self and super) and
  # return an attribute set of updated Haskell packages.
  #
  # Returns an updated Haskell package set.
  overrideHaskellPackages = f: packages:
    packages.override
      (orig: {
        overrides =
          lib.composeExtensions
            (orig.overrides or (_: _: { }))
            f;
      });

  # The name of a package derived from its cabal file name:
  nameFromCabal = cabal:
    lib.removeSuffix ".cabal" (baseNameOf (toString cabal));

  # Generate a Haskell package from a cabal file.
  derivationFromCabal =
    { cabal
    , flags
    , postPatch
    , addDataFiles
    , buildInputs
    , packages
    }:
    let
      # All flags as a string:
      flagsStr =
        lib.concatMapStringsSep " " (f: "-f${f}") flags;

      # Load the cabal file:
      cabal2nix =
        haskell.cleanSource (dirOf cabal)
          (packages.callCabal2nixWithOptions
            (nameFromCabal cabal)
            (dirOf cabal)
            flagsStr
            { });

      # The final derivation all patched up:
      drv =
        haskell.appendDataFiles ghc addDataFiles
          (haskell.appendPostPatch postPatch
            (haskell.doBenchmark # To get all deps.
              (haskell.appendBuildInputs buildInputs cabal2nix)));
    in
    drv;
}
