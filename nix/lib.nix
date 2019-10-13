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
# Extra library functions:
{ pkgs }: with pkgs.lib;

let

  haskellSourceFilter = name: type:
    let baseName = baseNameOf (toString name); in ! (
      baseName == "dist" ||
      baseName == "dist-newstyle" ||
      baseName == "TAGS" ||
      hasPrefix ".ghc.environment" baseName
    );

in rec {

  # A source cleaner for Haskell programs:
  cleanSource = src:
    cleanSourceWith {
      inherit src;
      filter = name: type:
        cleanSourceFilter   name type &&
        haskellSourceFilter name type;
    };

  # Override a derivation so that its source is smaller:
  overrideSrc = src: drv:
    pkgs.haskell.lib.overrideCabal drv
    (_: {src = cleanSource src;});

  # Append some build inputs:
  appendBuildInputs = buildInputs: drv:
    drv.overrideAttrs (orig: {
      buildInputs = orig.buildInputs ++ buildInputs;
    });

  # Enable benchmarks (not sure why this isn't the default):
  benchmark = drv: pkgs.haskell.lib.doBenchmark drv;

  # Missing from Haskell lib:
  unBreak = drv: with pkgs.haskell.lib;
    overrideCabal drv (_: {
      broken  = false;
      patches = [ ];
    });

  # Fetch a dependency from Git and provide it with the updated
  # package set.
  fetchGit = args:
    let src = builtins.fetchGit args;
    in import "${src}/default.nix" { inherit pkgs; };
}
