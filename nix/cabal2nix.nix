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
{ pkgs, cabal, flags }:
with pkgs.lib;

let
  # The package name derived from the cabal file name:
  name = removeSuffix ".cabal" (baseNameOf (toString cabal));

  # All flags as a string:
  flagsStr = concatMapStringsSep " " (f: "-f${f}") flags;

in pkgs.stdenvNoCC.mkDerivation {
  name = "${name}.nix";
  src = cabal;

  buildInputs = with pkgs; [ cabal2nix ];

  buildCommand = ''
    cabal2nix ${flagsStr} $(dirname ${cabal}) > $out
  '';
}
