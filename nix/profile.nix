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
# Helper file for post-processing Haskell profiles.
{ pkgs ? import <nixpkgs> { }
, compiler ? "default" # Which version of GHC to use, or "default".
}:

let
  # Select a compiler:
  basePackages = if compiler == "default" then
    pkgs.haskellPackages
  else
    pkgs.haskell.packages."ghc${compiler}";

in pkgs.mkShell {
  buildInputs = [
    basePackages.ghc # For hp2ps
    basePackages.ghc-prof-aeson-flamegraph
    pkgs.ghostscript # For ps2pdf
    pkgs.flamegraph # For flamegraph.pl
  ];

  shellHook = ''
    process_haskell_hp_file() {
      dir=$(dirname "$1")
      base=$(basename "$1" ".hp")

      (
        set -e
        cd $dir
        hp2ps -e11in -M -c "$base".hp
        ps2pdf "$base".ps
        rm -f "$base".ps "$base".aux
      )
    }
  '';
}
